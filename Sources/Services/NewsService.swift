import Foundation

// News sources for scraping
private enum NewsSource: String, CaseIterable {
    case pitchfork = "https://pitchfork.com/news"
    case billboard = "https://www.billboard.com/music"
    case rollingstone = "https://www.rollingstone.com/music"
    case nme = "https://www.nme.com/music"
    
    var baseUrl: String { rawValue }
}

// NewsAPI.org response models for internal use
struct NewsAPIArticle: Codable {
    let source: NewsAPISource
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?
}

struct NewsAPISource: Codable {
    let id: String?
    let name: String
}

struct NewsAPIResponseData: Codable {
    let status: String
    let totalResults: Int
    let articles: [NewsAPIArticle]
}

// Implementation of the Models.NewsAPIResponse protocol
struct NewsAPIResponseImpl: Models.NewsAPIResponse {
    let articles: [Models.NewsArticle]
}

public class NewsService {
    public static let shared = NewsService()
    private let apiKey = "e5d625694eef4943b02a393004694d0e"
    private let baseURL = "https://newsapi.org/v2"
    
    // Track API request status
    private var lastAPIRequestTime: Date?
    private var apiRequestsRemaining: Int = 100 // Default daily limit for free tier
    
    private init() {}
    
    public func getMusicNews(genre: String?, searchTerm: String? = nil) async throws -> [Models.NewsArticle] {
        // Use Task group to handle potential failures gracefully
        return try await withThrowingTaskGroup(of: [Models.NewsArticle].self) { group in
            // Add API task
            group.addTask {
                do {
                    return try await self.getNewsFromAPI(genre: genre, searchTerm: searchTerm)
                } catch {
                    print("API news fetch error: \(error)")
                    return [] // Return empty array on failure
                }
            }
            
            // Add scraping task
            group.addTask {
                do {
                    return try await self.getScrapedNews(searchTerm: searchTerm, genre: genre)
                } catch {
                    print("Scraped news fetch error: \(error)")
                    return [] // Return empty array on failure
                }
            }
            
            // Collect and combine results
            var allArticles: [Models.NewsArticle] = []
            for try await articles in group {
                allArticles.append(contentsOf: articles)
            }
            
            // Sort by date (newest first) and return
            return allArticles.sorted { $0.publishedAt > $1.publishedAt }
        }
    }
    
    private func getNewsFromAPI(genre: String?, searchTerm: String?) async throws -> [Models.NewsArticle] {
        // Check if we should rate limit our requests
        if let lastRequest = lastAPIRequestTime, Date().timeIntervalSince(lastRequest) < 1.0 {
            // Wait a bit to avoid hitting rate limits
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        var urlComponents = URLComponents(string: "\(baseURL)/everything")!
        
        // Create query with music-related terms and search term
        var queryTerms = ["music"]
        if let genre = genre, !genre.isEmpty {
            queryTerms.append(genre)
        }
        if let searchTerm = searchTerm, !searchTerm.isEmpty {
            queryTerms.append(searchTerm)
        }
        let query = queryTerms.joined(separator: " ")
        
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sortBy", value: "publishedAt"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "pageSize", value: "20"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        guard let url = urlComponents.url else {
            throw NSError(domain: "NewsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Track request time
        lastAPIRequestTime = Date()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NewsService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // Check for rate limiting headers
        if let remainingRequests = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining") {
            apiRequestsRemaining = Int(remainingRequests) ?? apiRequestsRemaining
        }
        
        // Handle error responses
        guard httpResponse.statusCode == 200 else {
            // If we're rate limited, throw a specific error
            if httpResponse.statusCode == 429 {
                throw NSError(domain: "NewsService", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded"])
            }
            
            // For other errors, try to parse the error message
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorResponse["message"] {
                throw NSError(domain: "NewsService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            
            throw NSError(domain: "NewsService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error with status code \(httpResponse.statusCode)"])
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(NewsAPIResponseData.self, from: data)
        
        // Convert API response to our model
        return apiResponse.articles.enumerated().compactMap { index, article in
            guard let url = URL(string: article.url) else {
                return nil
            }
            
            // Use a default description if none is provided
            let description = article.description ?? "No description available"
            
            let imageUrl = article.urlToImage != nil ? URL(string: article.urlToImage!) : nil
            
            // Parse date with fallback
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime]
            let date = dateFormatter.date(from: article.publishedAt) ?? Date()
            
            return Models.NewsArticle(
                id: "api-\(index)",
                title: article.title,
                description: description,
                url: url,
                imageUrl: imageUrl,
                publishedAt: date,
                source: article.source.name
            )
        }
    }
    
    private func getScrapedNews(searchTerm: String?, genre: String?) async throws -> [Models.NewsArticle] {
        var allArticles: [Models.NewsArticle] = []
        let searchTermLower = searchTerm?.lowercased()
        let genreLower = genre?.lowercased()
        
        // Focus on NME since it works best with our scraping approach
        let nmeSource = NewsSource.nme
        
        do {
            guard let url = URL(string: nmeSource.baseUrl) else { 
                throw NSError(domain: "NewsService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for NME"]) 
            }
            
            // Create a URLRequest with headers to mimic a browser
            var request = URLRequest(url: url)
            request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let htmlString = String(data: data, encoding: .utf8) else { 
                throw NSError(domain: "NewsService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid HTML encoding"]) 
            }
            
            // Extract articles using improved regex pattern for NME
            let articles = try await extractArticlesFromNME(from: htmlString)
            
            // Filter articles based on search term and genre if provided
            let filteredArticles = articles.filter { article in
                let matchesSearch = searchTermLower.map { 
                    article.title.lowercased().contains($0) || 
                    article.description.lowercased().contains($0)
                } ?? true
                
                let matchesGenre = genreLower.map {
                    article.title.lowercased().contains($0) ||
                    article.description.lowercased().contains($0)
                } ?? true
                
                return matchesSearch && matchesGenre
            }
            
            allArticles.append(contentsOf: filteredArticles)
        } catch {
            print("Error scraping NME: \(error)")
            // Continue with empty articles rather than throwing
        }
        
        return allArticles
    }
    
    private func extractArticlesFromNME(from html: String) async throws -> [Models.NewsArticle] {
        var articles: [Models.NewsArticle] = []
        
        // Improved regex pattern specifically for NME
        let articlePattern = try NSRegularExpression(
            pattern: "<h3[^>]*class=\"[^\"]*entry-title[^\"]*\"[^>]*>\\s*<a[^>]*href=\"([^\"]+)\"[^>]*>([^<]+)</a>",
            options: [.dotMatchesLineSeparators]
        )
        
        let matches = articlePattern.matches(
            in: html,
            options: [],
            range: NSRange(html.startIndex..., in: html)
        )
        
        for (index, match) in matches.enumerated() {
            guard match.numberOfRanges >= 3,
                  let urlRange = Range(match.range(at: 1), in: html),
                  let titleRange = Range(match.range(at: 2), in: html) else {
                continue
            }
            
            let urlString = String(html[urlRange])
            guard let url = URL(string: urlString) else { continue }
            
            let title = String(html[titleRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "&#8217;", with: "'") // Fix HTML entities
            
            // For NME, we don't have descriptions in the list view, so we use a placeholder
            let description = "Click to read more about this music news article from NME."
            
            let article = Models.NewsArticle(
                id: "nme-\(index)",
                title: title,
                description: description,
                url: url,
                imageUrl: nil,
                publishedAt: Date(), // Use current date as we don't have the actual date
                source: "NME"
            )
            
            articles.append(article)
        }
        
        return articles
    }
    
    public func getAvailableGenres() async throws -> [String] {
        return ["Rock", "Pop", "Hip-Hop", "Jazz", "Classical", "Electronic", "Country", "R&B", "Folk", "Metal", "Indie", "Alternative", "Festival", "Awards", "Technology"]
    }
    
    // Helper method to check API status
    public func getAPIStatus() async -> (isAvailable: Bool, requestsRemaining: Int) {
        do {
            // Make a minimal request to check status
            var urlComponents = URLComponents(string: "\(baseURL)/everything")!
            urlComponents.queryItems = [
                URLQueryItem(name: "q", value: "test"),
                URLQueryItem(name: "pageSize", value: "1"),
                URLQueryItem(name: "apiKey", value: apiKey)
            ]
            
            guard let url = urlComponents.url else {
                return (false, 0)
            }
            
            let request = URLRequest(url: url)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, 0)
            }
            
            // Update remaining requests if available
            if let remainingRequests = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining") {
                apiRequestsRemaining = Int(remainingRequests) ?? apiRequestsRemaining
            }
            
            return (httpResponse.statusCode == 200, apiRequestsRemaining)
        } catch {
            return (false, 0)
        }
    }
}
