/*
 MIT License

 Copyright 2023 - Present, Shopify Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

//
//  GraphQLDocument.swift
//  ShopifyAcceleratedCheckouts
//

import Foundation

/// Container around a GraphQL language string.
/// Includes necessary fragments for the operation.
@available(iOS 17.0, *)
struct GraphQLDocument {
    static func build(operation: Queries) -> String { _build(operation.rawValue) }
    static func build(operation: Mutations) -> String { _build(operation.rawValue) }

    private static func _build(_ operation: String) -> String {
        let analysis = analyzeFragments(in: operation)

        guard !analysis.allFragments.isEmpty else { return operation }

        let sortedFragments = sortFragments(
            analysis.allFragments,
            directReferences: analysis.directReferences
        )

        let fragmentDefinitions = sortedFragments
            .map(\.rawValue)
            .joined(separator: "\n\n")

        return """
        \(operation)

        \(fragmentDefinitions)
        """
    }

    /// Analyzes an operation to find all fragments and which are directly referenced
    private struct FragmentAnalysis {
        let allFragments: Set<Fragments>
        let directReferences: Set<Fragments>
    }

    /// Analyzes fragments in the operation, returning both direct references and all transitive dependencies
    private static func analyzeFragments(in operation: String) -> FragmentAnalysis {
        let fragmentPattern = #"\.\.\.([\w]+)"#
        guard let regex = try? NSRegularExpression(pattern: fragmentPattern, options: []) else {
            return FragmentAnalysis(allFragments: [], directReferences: [])
        }

        // Find direct references in the operation
        let directReferences = findFragmentReferences(in: operation, using: regex)

        // Find all fragments including transitive dependencies
        let allFragments = expandWithDependencies(directReferences, using: regex)

        return FragmentAnalysis(
            allFragments: allFragments,
            directReferences: directReferences
        )
    }

    /// Finds fragment references in a text string
    private static func findFragmentReferences(in text: String, using regex: NSRegularExpression) -> Set<Fragments> {
        var fragments = Set<Fragments>()
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))

        for match in matches {
            if let range = Range(match.range(at: 1), in: text) {
                let fragmentName = String(text[range])
                if let fragment = fragmentByName(fragmentName) {
                    fragments.insert(fragment)
                }
            }
        }

        return fragments
    }

    /// Expands a set of fragments to include all their transitive dependencies
    private static func expandWithDependencies(_ initialFragments: Set<Fragments>, using regex: NSRegularExpression) -> Set<Fragments> {
        var allFragments = Set<Fragments>()
        var toProcess = Array(initialFragments)

        while let current = toProcess.popLast() {
            guard allFragments.insert(current).inserted else {
                continue
            }

            // Find dependencies in this fragment's definition
            let dependencies = findFragmentReferences(in: current.rawValue, using: regex)
            toProcess.append(contentsOf: dependencies)
        }

        return allFragments
    }

    /// Finds a fragment by its name
    private static func fragmentByName(_ name: String) -> Fragments? {
        Fragments.allCases.first { fragmentName(of: $0) == name }
    }

    /// Extracts the fragment name from a fragment definition
    private static func fragmentName(of fragment: Fragments) -> String {
        let pattern = #"fragment\s+(\w+)\s+on"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return ""
        }

        let definition = fragment.rawValue
        if
            let match = regex.firstMatch(in: definition, options: [], range: NSRange(definition.startIndex..., in: definition)),
            let range = Range(match.range(at: 1), in: definition)
        {
            return String(definition[range])
        }

        return ""
    }

    /// Sorts fragments with direct references first, followed by their dependencies
    private static func sortFragments(_ fragments: Set<Fragments>, directReferences: Set<Fragments>) -> [Fragments] {
        // Build dependency graph
        let graph = buildDependencyGraph(fragments)

        // Perform topological sort
        let sorted = topologicalSort(fragments, graph: graph)

        // Partition into direct references and dependencies, preserving topological order
        let (direct, deps) = sorted.reduce(into: (direct: [Fragments](), deps: [Fragments]())) { result, fragment in
            if directReferences.contains(fragment) {
                result.direct.append(fragment)
            } else {
                result.deps.append(fragment)
            }
        }

        // Direct references first, then dependencies
        return direct + deps
    }

    /// Builds a dependency graph for the given fragments
    private static func buildDependencyGraph(_ fragments: Set<Fragments>) -> [Fragments: Set<Fragments>] {
        let pattern = #"\.\.\.([\w]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [:]
        }

        var graph: [Fragments: Set<Fragments>] = [:]

        for fragment in fragments {
            let dependencies = findFragmentReferences(in: fragment.rawValue, using: regex)
                .intersection(fragments) // Only include dependencies that are in our set
            graph[fragment] = dependencies
        }

        return graph
    }

    /// Performs a topological sort on fragments based on their dependencies
    private static func topologicalSort(_ fragments: Set<Fragments>, graph: [Fragments: Set<Fragments>]) -> [Fragments] {
        var result: [Fragments] = []
        var visited = Set<Fragments>()

        // For stable ordering
        let orderedFragments = fragments.sorted { fragment1, fragment2 in
            Fragments.allCases.firstIndex(of: fragment1)! < Fragments.allCases.firstIndex(of: fragment2)!
        }

        func visit(_ fragment: Fragments) {
            guard !visited.contains(fragment) else { return }
            visited.insert(fragment)

            // Visit dependencies first
            if let dependencies = graph[fragment] {
                for dependency in dependencies.sorted(by: { Fragments.allCases.firstIndex(of: $0)! < Fragments.allCases.firstIndex(of: $1)! }) {
                    visit(dependency)
                }
            }

            result.append(fragment)
        }

        for fragment in orderedFragments {
            visit(fragment)
        }

        return result
    }
}
