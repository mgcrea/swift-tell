import Foundation

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

public struct StderrOutputStream: TextOutputStream {
  public mutating func write(_ string: String) {
    fputs(string, stderr)
  }
}

public var errStream = StderrOutputStream()
