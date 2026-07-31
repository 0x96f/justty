//
//  ProcessWorkingDirectory.swift
//  justty
//

import Darwin
import Foundation

/// Resolves a process cwd for new-tab inheritance without Ghostty shell integration.
enum ProcessWorkingDirectory {
    /// Prefer OSC 7 when usable; else shell/foreground pid cwd; else home.
    nonisolated static func resolve(
        reportedPath: String?,
        shellPid: pid_t?,
        foregroundPid: pid_t?,
        home: String = NSHomeDirectory(),
        processCwd: (pid_t) -> String? = cwd(of:),
        isDirectory: (String) -> Bool = isUsableDirectory(_:)
    ) -> String {
        if let reportedPath, isDirectory(reportedPath) {
            return reportedPath
        }
        for pid in [shellPid, foregroundPid].compactMap({ $0 }) {
            if let path = processCwd(pid), isDirectory(path) {
                return path
            }
        }
        return home
    }

    nonisolated static func isUsableDirectory(_ path: String) -> Bool {
        guard !path.isEmpty else { return false }
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
            && isDir.boolValue
    }

    /// Current working directory of `pid` via `PROC_PIDVNODEPATHINFO`.
    nonisolated static func cwd(of pid: pid_t) -> String? {
        var info = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &info, size)
        guard result == size else { return nil }
        return withUnsafeBytes(of: info.pvi_cdir.vip_path) { raw in
            guard let base = raw.bindMemory(to: CChar.self).baseAddress else {
                return nil
            }
            let path = String(cString: base)
            return path.isEmpty ? nil : path
        }
    }
}
