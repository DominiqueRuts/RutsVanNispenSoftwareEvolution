/*
 * course : Software Evolution (IM0202) Assignment 2: Software Visualization
 * authors: Johan van Nispen (836541627) and Dominique Ruts (852059122)
 * date   : 18/01/2019
 */

module filecontroller

import IO;
import Set;
import String;
import ValueIO;
import util::Resources;
import lang::java::jdt::m3::Core;

import Type;
import List;
import qprofile;

private set[loc] files = {};
private bool initialLoad = true;

// project default location setting for file output
public str locationPath = "RutsVanNispenSoftwareEvolution/src/output/";

// return the project loc based on the project name
public loc getProjectLocation(str projectName) {
	initialLoad = true;
	return |project://<projectName>/|;
}

// read the project into M3 model
// returns a map of (location:methods (as string))
public map[loc, str] readMethods(loc project) {
	M3 model = createM3FromEclipseProject(project);
	return (a:readFile(a) | a <- methods(model));
}

// returns the number of relevant files in the project
public set[loc] getProjectFiles(Resource r) {
	if (initialLoad) {
		initialLoad = false;
		files = { a | /file(a) <- r, a.extension == "java" };
	}
	return files;
}

// returns the number of relevant files in the project
public int getProjectFilesCount() {
	return size(files);
}
   
public void schrijf(str fileName, value v) {
   writeTextValueFile(|project://<locationPath><fileName>/|, v);
}

public int lees(str fileName, type[int] t) {	
   return readTextValueFile(#int, |project://<locationPath><fileName>/|);
}

public list[MethodStat] lees(str fileName, type[list[MethodStat]] t) {	
   return readTextValueFile(#list[MethodStat], |project://<locationPath><fileName>/|);
}
