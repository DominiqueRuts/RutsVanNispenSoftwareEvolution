module JavaAnalyzer

import IO;
import List;
import Map;
import Relation;
import Set;
import String;
import analysis::graphs::Graph;
import util::Resources;
import lang::java::jdt::m3::Core;

//Project specific modules
import FileController;
import Sorting;

private set[loc] javaFiles;

public void main(str fileName) {
	javaFiles = getJavaFiles(fileName);
	
	println("<size(javaFiles)> files");
	println();
}