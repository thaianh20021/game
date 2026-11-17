using System;
using UnityEditor;
using UnityEngine;

// Starts the MCP for Unity bridge (stdio) whenever the editor loads this project, so an assistant can
// drive the open editor without anyone clicking through the package's window first. Found by reflection:
// the project still compiles if the package is removed.
[InitializeOnLoad]
public static class McpBoot {
	static McpBoot() {
		if (Application.isBatchMode) return;
		EditorApplication.delayCall += () => {
			try {
				foreach (var asm in AppDomain.CurrentDomain.GetAssemblies()) {
					var t = asm.GetType("MCPForUnity.Editor.McpCiBoot");
					if (t == null) continue;
					t.GetMethod("StartStdioForCi").Invoke(null, null);
					Debug.Log("McpBoot: MCP stdio bridge started");
					return;
				}
			} catch (Exception e) { Debug.LogWarning("McpBoot: " + e.Message); }
		};
	}
}
