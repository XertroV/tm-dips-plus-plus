class TOctTreeNode {
    vec3 min;
    vec3 max;
    int depth;
    TOctTreeNode@ parent;

    TOctTreeNode(vec3 min, vec3 max, int depth, TOctTreeNode@ parent = null) {
        this.min = min;
        this.max = max;
        this.depth = depth;
        @this.parent = parent;
    }
}
class TOctTree {

}
