using System;
using System.IO;
using UnityEngine;

namespace BackpackRoyale.Rebuild
{
    public static class SaveService
    {
        public static void Save(string path, SaveDataV1 data)
        {
            if (string.IsNullOrWhiteSpace(path) || data == null)
                throw new ArgumentException("Save path and data are required");
            EnsureDirectory(path);
            File.WriteAllText(path, JsonUtility.ToJson(data, true));
        }

        public static bool TryLoad(string path, out SaveDataV1 data)
        {
            data = null;
            if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
                return false;
            try
            {
                string json = File.ReadAllText(path);
                data = JsonUtility.FromJson<SaveDataV1>(json);
                return data != null && data.saveVersion == 1;
            }
            catch (Exception)
            {
                data = null;
                return false;
            }
        }

        public static void SaveV2(string path, SaveDataV2 data)
        {
            if (string.IsNullOrWhiteSpace(path) || data == null)
                throw new ArgumentException("Save path and data are required");
            data.saveVersion = 2;
            EnsureDirectory(path);
            File.WriteAllText(path, JsonUtility.ToJson(data, true));
        }

        public static bool TryLoadV2(string path, out SaveDataV2 data)
        {
            data = null;
            if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
                return false;
            try
            {
                string json = File.ReadAllText(path);
                data = JsonUtility.FromJson<SaveDataV2>(json);
                if (data == null || data.saveVersion != 2)
                {
                    data = null;
                    return false;
                }
                if (data.items == null)
                    data.items = new System.Collections.Generic.List<SaveItemV2>();
                if (data.completedNodeIds == null)
                    data.completedNodeIds = new System.Collections.Generic.List<string>();
                return true;
            }
            catch (Exception)
            {
                data = null;
                return false;
            }
        }

        public static void Delete(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
                return;
            try
            {
                if (File.Exists(path))
                    File.Delete(path);
            }
            catch (IOException)
            {
                // A checkpoint failure must never crash the run.
            }
            catch (UnauthorizedAccessException)
            {
                // Keep the existing checkpoint when the platform denies deletion.
            }
        }

        private static void EnsureDirectory(string path)
        {
            string directory = Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(directory))
                Directory.CreateDirectory(directory);
        }
    }
}
