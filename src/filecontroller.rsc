/*
 * course : Software Evolution (IM0202) Assignment 1: Software Metrics
 * authors: Johan van Nispen (836541627) and Dominique Ruts (852059122)
 * date   : 12/12/2018
 */

module filecontroller

import IO;
import Set;
import String;
import util::Resources;
import lang::java::jdt::m3::Core;

private set[loc] files = {};
private bool initialLoad = true;

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