using System;
using System.Collections.Generic;

namespace BackpackRoyale.Rebuild
{
    [Serializable]
    public sealed class SaveItemV2
    {
        public string instanceId;
        public string itemId;
        public int x;
        public int y;
        public bool rotated;
    }

    [Serializable]
    public sealed class SaveDataV2
    {
        public int saveVersion=2;
        public string heroId;
        public int gold;
        public int round;
        public int lives;
        public int runSeed;
        public string currentNodeId;
        public bool currentNodeResolved;
        public List<string> completedNodeIds = new List<string>();
        public float runHealthBonus;
        public List<SaveItemV2> items = new List<SaveItemV2>();
    }
}
