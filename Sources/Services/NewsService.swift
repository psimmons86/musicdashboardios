import Foundation

public class NewsService {
    public static let shared = NewsService()
    private let apiKey = "e5d625694eef4943b02a393004694d0e"
    private let baseURL = "https://newsapi.org/v2"
    
    private init() {}
    
    private let genreKeywords: [String: String] = [
        "Rock": "rock music OR guitar OR band",
        "Hip-Hop": "hip hop OR rap OR rapper",
        "Classical": "classical music OR orchestra OR symphony",
        "Pop": "pop music OR pop star OR billboard",
        "Jazz": "jazz music OR blues",
        "Electronic": "electronic music OR edm OR dj",
        "Country": "country music OR nashville",
        "R&B": "r&b music OR soul music"
    ]
    
    public func getMusicNews(genre: String? = nil) async throws -> [NewsArticle] {
        var components = URLComponents(string: "\(baseURL)/everything")!
        
        // Base query for music news
        var query = "music AND (concert OR album OR artist OR song OR performance)"
        
        // Add genre-specific keywords if a genre is selected
        if let genre = genre, let genreQuery = genreKeywords[genre] {
            query += " AND (\(genreQuery))"
        }
        
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sortBy", value: "publishedAt"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "pageSize", value: "10")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
        return response.articles
    }
    
    public func getAvailableGenres() async throws -> [String] {
        return Array(genreKeywords.keys).sorted()
    }
}

private struct NewsAPIResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [NewsArticle]
}
