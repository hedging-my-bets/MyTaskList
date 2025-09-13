import Foundation

public extension Array {
    subscript(safe index: Int) -> Element? {
        return (0..<count).contains(index) ? self[index] : nil
    }
}