//
//  File.swift
//  
//
//  Created by CodeBuilder on 15/10/2023.
//

import Foundation
import CryptoKit
import PathKit

extension PathKit.Path {
	
	private func getSHA256(forFile url: URL) throws -> SHA256.Digest {
		let handle = try FileHandle(forReadingFrom: url)
		var hasher = SHA256()
		while autoreleasepool(invoking: {
			let nextChunk = handle.readData(ofLength: SHA256.blockByteCount)
			guard !nextChunk.isEmpty else { return false }
			hasher.update(data: nextChunk)
			return true
		}) { }
		let digest = hasher.finalize()
		print(url.path(), digest.description)
		return digest
		
		// Here's how to convert to string form
		//return digest.map { String(format: "%02hhx", $0) }.joined()
	}
	
	
	public func sha256() throws -> String {
		let sha = try getSHA256(forFile: self.url)
		return sha.map { String(format: "%02hhx", $0) }.joined()
	}
}

public struct PackageBinaryTarget {
	public let path: Path
	
	public var filename: String { path.lastComponentWithoutExtension }
	public var file: String { path.lastComponent }
	
	public var sha: String { (try? path.sha256()) ?? "" }
	public init(path: Path) {
		self.path = path
	}
}



class ShaFiles {
	
	init() throws {
		let binaryTargets = Path("/Volumes/CodeSSD/actions-runner/_work/KivyCoreBuilder/KivyCoreBuilder/output/kivy/xcframework")
			.filter({$0.extension == "zip"})
			.map(PackageBinaryTarget.init)
		
	}
}
