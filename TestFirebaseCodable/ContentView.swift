//
//  ContentView.swift
//  TestFirebaseCodable
//
//  Created by A_Mcflurry on 12/4/24.
//

import SwiftUI
import CodableFirebase

struct ContentView: View {
    var body: some View {
        VStack {
            if let user = User(fromFirebaseJSON: firebaseJSON) {
                Text("\(user)")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}


// 예시 모델
struct User: Codable {
    let name: String
    let age: Int
    let scores: [Double]?
}

extension User {
    // Firebase JSON을 일반 JSON으로 변환한 후 디코딩하는 이니셜라이저
    init?(fromFirebaseJSON json: [String: Any]) {
        // 먼저 Firebase JSON을 일반 JSON으로 변환
        guard let parsedJSON = FirebaseParser.parseFirebaseValue(json) as? [String: Any],
              let jsonData = try? JSONSerialization.data(withJSONObject: parsedJSON) else {
            return nil
        }
        
        // JSONDecoder를 사용하여 모델로 변환
        do {
            let decoder = JSONDecoder()
            self = try decoder.decode(User.self, from: jsonData)
        } catch {
            print("Decoding error: \(error)")
            return nil
        }
    }
}

// 사용 예시
let firebaseJSON: [String: Any] = [
    "name": ["stringValue": "John Doe"],
    "age": ["integerValue": "30"],
    "scores": ["arrayValue": ["values": [
        ["doubleValue": "95.5"],
        ["doubleValue": "87.5"]
    ]]]
]


struct FirebaseParser {
    static func parseFirebaseValue(_ value: [String: Any]) -> Any? {
        let firebaseProps: Set<String> = [
            "arrayValue", "bytesValue", "booleanValue",
            "doubleValue", "geoPointValue", "integerValue",
            "mapValue", "nullValue", "referenceValue",
            "stringValue", "timestampValue"
        ]
        
        guard let prop = firebaseProps.first(where: { value.keys.contains($0) }) else {
            // 일반 객체인 경우
            if var dict = value as? [String: Any] {
                for (key, val) in dict {
                    dict[key] = parseFirebaseValue(val as? [String: Any] ?? [:])
                }
                return dict
            }
            return value
        }
        
        switch prop {
        case "doubleValue", "integerValue":
            return Double(value[prop] as? String ?? "0")
        
        case "arrayValue":
            let values = (value[prop] as? [String: Any])?["values"] as? [[String: Any]] ?? []
            return values.map { parseFirebaseValue($0) }
        
        case "mapValue":
            let fields = (value[prop] as? [String: Any])?["fields"] as? [String: Any] ?? [:]
            return parseFirebaseValue(fields)
        
        case "geoPointValue":
            return value[prop]
        
        default:
            return value[prop]
        }
    }
}
