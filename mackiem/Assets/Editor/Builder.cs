using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;

// Sets up the project (one empty scene: the game builds itself at runtime) and makes the Windows build.
// Batch: Unity.exe -batchmode -quit -projectPath . -executeMethod Builder.Build
public static class Builder {
	[MenuItem("MacKiem/Setup")]
	public static void Setup() {
		PlayerSettings.companyName = "ThaiAnh";
		PlayerSettings.productName = "MacKiemLuc";
		PlayerSettings.colorSpace = ColorSpace.Gamma;
		PlayerSettings.defaultScreenWidth = 1280;
		PlayerSettings.defaultScreenHeight = 720;
		PlayerSettings.fullScreenMode = FullScreenMode.Windowed;
		PlayerSettings.resizableWindow = true;
		PlayerSettings.runInBackground = true;
		if (!File.Exists("Assets/Main.unity")) {
			var s = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
			EditorSceneManager.SaveScene(s, "Assets/Main.unity");
		}
		EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene("Assets/Main.unity", true) };
		AssetDatabase.SaveAssets();
	}

	[MenuItem("MacKiem/Build Windows")]
	public static void Build() {
		Setup();
		var r = BuildPipeline.BuildPlayer(new[] { "Assets/Main.unity" }, "Build/MacKiemLuc.exe", BuildTarget.StandaloneWindows64, BuildOptions.None);
		Debug.Log("BUILD RESULT " + r.summary.result + " errors=" + r.summary.totalErrors);
		if (Application.isBatchMode) EditorApplication.Exit(r.summary.result == BuildResult.Succeeded ? 0 : 1);
	}
}

// Every picture under Resources/Art is a sprite: 200 px per unit (drawn at twice the logic size), feet at the bottom centre.
public class ArtImport : AssetPostprocessor {
	void OnPreprocessTexture() {
		if (!assetPath.Contains("Resources/Art")) return;
		var ti = (TextureImporter)assetImporter;
		string n = Path.GetFileNameWithoutExtension(assetPath);
		bool big = n.StartsWith("bg") || n == "title";
		ti.textureType = TextureImporterType.Sprite;
		ti.spriteImportMode = SpriteImportMode.Single;
		ti.mipmapEnabled = false;
		ti.alphaIsTransparency = !big;
		ti.filterMode = FilterMode.Bilinear;
		ti.textureCompression = TextureImporterCompression.Uncompressed;
		ti.maxTextureSize = 2048;
		ti.wrapMode = TextureWrapMode.Clamp;
		var st = new TextureImporterSettings();
		ti.ReadTextureSettings(st);
		st.spritePixelsPerUnit = big ? 100 : 200;
		st.spriteAlignment = (int)(big ? SpriteAlignment.Center : SpriteAlignment.BottomCenter);
		st.spriteMeshType = SpriteMeshType.FullRect;
		ti.SetTextureSettings(st);
	}
}
