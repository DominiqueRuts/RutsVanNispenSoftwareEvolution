module filecontroller

import IO;
import Set;
import String;
import util::Resources;
import lang::java::jdt::m3::Core;

// return the project loc based on the project name
public loc getProjectLoc(str projectName) {
	return |project://<projectName>/|;
}

// read the project into M3 model
// returns a map of (location:methods (as string))
public map[loc, str] readMethods(loc project) {
	M3 model = createM3FromEclipseProject(project);
	return (a:readFile(a) | a <- methods(model));
}

// returns the number of relevant files in the project
public int getProjectFiles(loc project) { 
  int tloc = 0;
  Resource r = getProject(project);
  set[loc] files = { a | /file(a) <- r, a.extension == "java" };
  return size(files);
}