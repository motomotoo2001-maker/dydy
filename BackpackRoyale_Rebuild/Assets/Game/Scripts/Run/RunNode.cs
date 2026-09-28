namespace BackpackRoyale.Rebuild
{
    public enum RunNodeType
    {
        Battle,
        Elite,
        Boss
    }

    public sealed class RunNode
    {
        public string Id { get; }
        public int Stage { get; }
        public RunNodeType Type { get; }
        public string Label { get; }

        public RunNode(string id, int stage, RunNodeType type, string label)
        {
            Id = id;
            Stage = stage;
            Type = type;
            Label = label;
        }
    }
}
