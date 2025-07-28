namespace ClsCount {
	dictionary classCounts;

	int64 GetCount(const string &in clsName) {
		if (classCounts.Exists(clsName)) {
			return int64(classCounts[clsName]);
		}
		return 0;
	}

	void LogConstruct(const string &in clsName) {
		classCounts[clsName] = GetCount(clsName) + 1;
	}

	void LogDestruct(const string &in clsName) {
		auto newCount = GetCount(clsName) - 1;
		classCounts[clsName] = newCount;
		if (newCount < 0) {
			Dev_NotifyWarning("Class " + clsName + " count went below 0: " + newCount);
		}
	}

	string[] sortedClassKeys;
	void RenderUI() {
		auto nbClassesTracked = classCounts.GetSize();
		auto nbSortedClasses = sortedClassKeys.Length;
		if (nbSortedClasses > 0 && nbClassesTracked != nbSortedClasses) {
			UI::Text("\\$i\\$f80Warning: Sorted Classes Stale!");
		}
		auto nbClasses = nbSortedClasses > 0 ? nbSortedClasses : nbClassesTracked;
		auto @clsKeys = nbSortedClasses > 0 ? sortedClassKeys : classCounts.GetKeys();
		if (nbClasses != clsKeys.Length) {
			UI::Text("\\$f44" + Icons::ExclamationTriangle + " !!!!! Class Count Mismatch: " + nbClasses + " != " + clsKeys.Length);
			nbClasses = clsKeys.Length;
		}
		UI::Text("# Classes Tracked: " + nbClasses);
		UI::Separator();
		UI::PushFont(UI::Font::DefaultMono);
		UI::Columns(2);
		for (uint i = 0; i < nbClasses; i++) {
			UI::Text("\\$i" + clsKeys[i]);
		}
		UI::NextColumn();
		for (uint i = 0; i < nbClasses; i++) {
			UI::Text(Text::Format("%08d", GetCount(clsKeys[i])));
		}
		UI::Columns(1);
		UI::PopFont();
	}
}
