using System.Collections.Generic;

namespace BackpackRoyale.Rebuild
{
    public sealed class RunMapState
    {
        private readonly List<RunNode> nodes;
        public IReadOnlyList<RunNode> Nodes => nodes;
        public int MaxStage { get; }

        public RunMapState(List<RunNode> valueNodes, int maxStage)
        {
            nodes = valueNodes ?? new List<RunNode>();
            MaxStage = maxStage;
        }

        public IReadOnlyList<RunNode> GetChoicesForStage(int stage)
        {
            var result = new List<RunNode>();
            for (int i = 0; i < nodes.Count; i++)
                if (nodes[i].Stage == stage)
                    result.Add(nodes[i]);
            return result;
        }
    }
}
