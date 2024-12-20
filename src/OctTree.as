

class OctTree {
    OctTreeNode@ root;

    // input is in blocks, not world units
    OctTree(vec3 &in mapSize = vec3(48, 255, 48)) {
        @root = OctTreeNode(null, 0, vec3(0, 0, 0), mapSize * vec3(32, 8, 32));
    }

    void Insert(const vec3 &in point) {
        root.Insert(point);
    }

    void Insert(OctTreeRegion@ region) {
        root.Insert(region);
    }

    bool Contains(const vec3 &in point) {
        return root.Contains(point);
    }

    // bool Contains(OctTreeRegion@ region) {
    //     return root.Contains(region);
    // }

    void Remove(const vec3 &in point) {
        root.Remove(point);
    }

    void Remove(OctTreeRegion@ region) {
        root.Remove(region);
    }

    OctTreeRegion@[]@ PointToRegions(const vec3 &in point) {
        return root.PointToRegions(point);
    }

    uint CountPoints() {
        return root.CountPoints();
    }

    uint CountRegions() {
        return root.CountRegions();
    }

    uint CountTotalNodes() {
        return root.CountTotalNodes();
    }
}

class OctTreeRegion {
    vec3 max;
    vec3 min;
    vec3 midp;
    vec3 size;
    bool isNode = false;
    string name;
    // mat4 mat;

    OctTreeRegion(vec3 &in min, vec3 &in max) {
        this.min = min;
        this.max = max;
        this.size = max - min;
        midp = (max + min) / 2.;
        name = "unnamed region";
    }

    string ToString() {
        return "Region " + name + " min: " + min.ToString() + " max: " + max.ToString();
    }

    bool PointInside(const vec3 &in point) {
        return point.x >= min.x && point.x <= max.x &&
            point.y >= min.y && point.y <= max.y &&
            point.z >= min.z && point.z <= max.z;
    }

    bool RegionInside(OctTreeRegion@ region) {
        return region.max.x <= max.x && region.max.y <= max.y && region.max.z <= max.z &&
            region.min.x >= min.x && region.min.y >= min.y && region.min.z >= min.z;
    }

    bool Intersects(OctTreeRegion@ region) {
        return region.max.x >= min.x && region.max.y >= min.y && region.max.z >= min.z &&
            region.min.x <= max.x && region.min.y <= max.y && region.min.z <= max.z;
    }

    // separate into 1-8 regions split at midpoint
    // OctTreeRegion@[] SubdivideAround(vec3 &in parentMidP) {
    //     OctTreeRegion@[] regions;
    //     return regions;
    // }
}

class OctTreeNode : OctTreeRegion {
    OctTreeNode@ parent;
    int depth;
    uint totalPoints = 0;
    uint totalRegions = 0;
    array<OctTreeNode@> children;
    // regions that don't fit in any child
    array<OctTreeRegion@> regions;
    // points if we have no children
    array<vec3> points;


    OctTreeNode(OctTreeNode@ parent, int depth, const vec3 &in min, const vec3 &in max) {
        super(min, max);
        isNode = true;
        @this.parent = parent;
        this.depth = depth;
    }

    bool Contains(const vec3 &in point) {
        if (point.x < min.x || point.x > max.x || point.y < min.y || point.y > max.y || point.z < min.z || point.z > max.z) {
            return false;
        }
        if (children.Length == 0) {
            for (uint i = 0; i < points.Length; i++) {
                if (points[i] == point) {
                    return true;
                }
            }
            return false;
        } else {
            return children[PointToIx(point)].Contains(point);
        }
    }



    bool Remove(const vec3 &in point) {
        if (children.Length == 0) {
            for (uint i = 0; i < points.Length; i++) {
                if (points[i] == point) {
                    points.RemoveAt(i);
                    totalPoints--;
                    return true;
                }
            }
        } else {
            if (children[PointToIx(point)].Remove(point)) {
                totalPoints--;
                return true;
            }
        }
        return false;
    }

    bool Remove(OctTreeRegion@ region) {
        if (children.Length == 0) {
            auto ix = regions.FindByRef(region);
            if (ix != -1) {
                regions.RemoveAt(ix);
                totalRegions--;
                return true;
            }
        } else {
            // remove it from the right child
            OctTreeNode@ child;
            for (uint i = 0; i < children.Length; i++) {
                @child = children[i];
                if (region.max.x < child.max.x && region.max.y < child.max.y && region.max.z < child.max.z &&
                    region.min.x > child.min.x && region.min.y > child.min.y && region.min.z > child.min.z
                ) {
                    if (child.Remove(region)) {
                        totalRegions--;
                        return true;
                    }
                }
            }
            auto ix = regions.FindByRef(region);
            if (ix != -1) {
                regions.RemoveAt(ix);
                totalRegions--;
                return true;
            }
        }
        return false;
    }

    uint PointToIx(const vec3 &in point) {
        uint ix = 0;
        if (point.x > midp.x) {
            ix += 4;
        }
        if (point.y > midp.y) {
            ix += 2;
        }
        if (point.z > midp.z) {
            ix += 1;
        }
        return ix;
    }

    void Subdivide() {
        // duplicate blocks or points would make this recurse forever
        if (depth >= 10) {
            return;
        }
        vec3 mid = (max + min) / 2;
        for (int i = 0; i < 2; i++) {
            for (int j = 0; j < 2; j++) {
                for (int k = 0; k < 2; k++) {
                    OctTreeNode@ child = OctTreeNode(this, depth + 1,
                        vec3(i * (mid.x - min.x) + min.x, j * (mid.y - min.y) + min.y, k * (mid.z - min.z) + min.z),
                        vec3((i + 1) * (mid.x - min.x) + min.x, (j + 1) * (mid.y - min.y) + min.y, (k + 1) * (mid.z - min.z) + min.z)
                    );
                    children.InsertLast(child);
                    // ix = i * 4 + j * 2 + k
                }
            }
        }
        // 000, 001, 010, 011, 100, 101, 110, 111
        // upper: x => 4, y => 2, z => 1, flags via ix

        for (uint i = 0; i < points.Length; i++) {
            children[PointToIx(points[i])].Insert(points[i]);
        }
        points.Resize(0);
        if (points.Length != 0) {
            throw("resize doesn't work");
        }
        OctTreeRegion@ region;
        for (uint i = 0; i < regions.Length; i++) {
            @region = regions[i];
            // remove all regions that fit in a child
            OctTreeNode@ child;
            for (uint j = 0; j < children.Length; j++) {
                @child = children[j];
                if (region.max.x < child.max.x && region.max.y < child.max.y && region.max.z < child.max.z &&
                    region.min.x > child.min.x && region.min.y > child.min.y && region.min.z > child.min.z
                ) {
                    child.Insert(region);
                    regions.RemoveAt(i);
                    i--;
                    break;
                }
            }
        }
        // // subdivide and insert the remaining regions
        // for (uint i = 0; i < regions.Length; i++) {
        //     auto subregions = regions[i].SubdivideAround(midp);
        //     for (uint j = 0; j < subregions.Length; j++) {
        //         children[PointToIx(subregions[j].midp)].Insert(subregions[j]);
        //     }
        // }
        // regions.Resize(0);
    }

    bool get_ShouldSubdivide() {
        return children.Length == 0 && points.Length + regions.Length > 8;
    }

    void Insert(const vec3 &in point) {
        if (children.Length == 0) {
            points.InsertLast(point);
            if (ShouldSubdivide) {
                Subdivide();
            }
        } else {
            children[PointToIx(point)].Insert(point);
        }
        totalPoints++;
    }

    void Insert(OctTreeRegion@ region) {
        if (children.Length == 0) {
            regions.InsertLast(region);
            if (ShouldSubdivide) {
                Subdivide();
            }
        } else {
            // add it to the right child unless it fits in none
            OctTreeNode@ child;
            bool inserted = false;
            for (uint i = 0; i < children.Length; i++) {
                @child = children[i];
                if (region.max.x < child.max.x && region.max.y < child.max.y && region.max.z < child.max.z &&
                    region.min.x > child.min.x && region.min.y > child.min.y && region.min.z > child.min.z
                ) {
                    child.Insert(region);
                    inserted = true;
                    break;
                }
            }
            if (!inserted) {
                // auto subregions = region.SubdivideAround(midp);
                // for (uint i = 0; i < subregions.Length; i++) {
                //     children[PointToIx(subregions[i].midp)].Insert(subregions[i]);
                // }
                regions.InsertLast(region);
            }
        }
        totalRegions++;
    }

    OctTreeRegion@[]@ PointToRegions(const vec3 &in point) {
        OctTreeRegion@[] ret;
        for (uint i = 0; i < regions.Length; i++) {
            if (regions[i].PointInside(point)) {
                ret.InsertLast(regions[i]);
            }
        }
        if (children.Length > 0) {
            auto r = children[PointToIx(point)].PointToRegions(point);
            for (uint i = 0; i < r.Length; i++) {
                ret.InsertLast(r[i]);
            }
        }
        return ret;
    }

    OctTreeRegion@ PointToFirstRegion(const vec3 &in point) {
        for (uint i = 0; i < regions.Length; i++) {
            if (regions[i].PointInside(point)) {
                return regions[i];
            }
        }
        if (children.Length > 0) {
            return children[PointToIx(point)].PointToFirstRegion(point);
        }
        return null;
    }

    OctTreeRegion@ PointToDeepestRegion(const vec3 &in point) {
        OctTreeRegion@ r;
        if (children.Length > 0) {
            @r = children[PointToIx(point)].PointToDeepestRegion(point);
        }
        if (r is null) {
            for (uint i = 0; i < regions.Length; i++) {
                if (regions[i].PointInside(point)) {
                    return regions[i];
                }
            }
        }
        return r;
    }

    bool PointHitsRegion(const vec3 &in point) {
        for (uint i = 0; i < regions.Length; i++) {
            if (regions[i].PointInside(point)) {
                return true;
            }
        }
        if (children.Length > 0) {
            return children[PointToIx(point)].PointHitsRegion(point);
        }
        return false;
    }

    uint CalculateNbPoints() {
        uint sum = points.Length;
        for (uint i = 0; i < children.Length; i++) {
            sum += children[i].CalculateNbPoints();
        }
        return sum;
    }

    uint CalculateNbRegions() {
        uint sum = regions.Length;
        for (uint i = 0; i < children.Length; i++) {
            sum += children[i].CalculateNbRegions();
        }
        return sum;
    }

    uint CountPoints() {
        return totalPoints;
    }

    uint CountRegions() {
        return totalRegions;
    }

    uint CountTotalNodes() {
        uint sum = 1;
        for (uint i = 0; i < children.Length; i++) {
            sum += children[i].CountTotalNodes();
        }
        return sum;
    }

    // void Debug_NvgDrawRegions() {
    //     for (uint i = 0; i < regions.Length; i++) {
    //         regions[i].Debug_NvgDrawTrigger();
    //         regions[i].Debug_NvgDrawTriggerName();
    //     }
    //     for (uint i = 0; i < children.Length; i++) {
    //         children[i].Debug_NvgDrawRegions();
    //     }
    // }
}
