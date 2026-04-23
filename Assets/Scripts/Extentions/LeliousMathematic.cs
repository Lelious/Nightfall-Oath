using UnityEngine;

namespace LeliousExtentions
{
    public static class LeliousMathematic
    {
        public static bool FlatDistanceGreaterThan(Vector2 pos1, Vector2 pos2, float distance)
        {
            var dx = pos1.x - pos2.x;
            var dy = pos1.y - pos2.y;
            var distSqr = dx * dx + dy * dy;
            return distSqr > distance * distance;
        }

        public static bool DistanceGreaterThan(Vector3 pos1, Vector3 pos2, float distance)
        {
            var dx = pos1.x - pos2.x;
            var dy = pos1.y - pos2.y;
            var dz = pos1.z - pos2.z;

            var distSqr = dx * dx + dy * dy + dz * dz;

            return distSqr > distance * distance;
        }

        public static bool GridDistanceGreaterThan(Vector2Int pos1, Vector2Int pos2, int distance)
        {
            var dx = pos1.x - pos2.x;
            var dy = pos1.y - pos2.y;

            return Mathf.Abs(dx) > distance || Mathf.Abs(dy) > distance;
        }
    }
}
