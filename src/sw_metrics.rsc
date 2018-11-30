module sw_metrics

import IO;
import Set;
import Relation;
import Map;
import List;
import util::Resources;
import lang::java::jdt::m3::Core;

// display a list of all project methods
public void printMethods(loc project) {
	M3 model = createM3FromEclipseProject(project);
	for (loc l <- methods(model)) {
		str s = readFile(l);
		println("=== <l> ===\n<s>");
	}
}

// read the project into M3 model
public map[loc, str] readMethods(loc project) {
	M3 model = createM3FromEclipseProject(project);
	return (a:readFile(a) | a <- methods(model));
}

// count the Lines Of Code (LOC) in a string
public int countLOC(str s) {
  int count = 0;
  // count the number of newline characters
  for (/[\n]+/ := s) {
       count += 1;
  } 
  // substract the number of blank lines
  for (/^[\s\t]*$/m := s) {
       if (count > 0) count -= 1;
  }
  // substract the number of comment lines (where comments start at the beginning)
  for (/^[\/\/]+/ := s) {
       if (count > 0) count -= 1;
  }
  return count;
}

// calculate the cyclomatic complexity of the supplied method
public int countComplexity(str s) {
  int count = 1; 
  // count the number of branching statements
  for (/\b(?:if|for|while|case)\b/ := s) {
       count += 1;
  }
  return count;
}

public int countAssert(str s) {
  int count = 0; 
  // count the number of assert statements
  for (/assert/i := s) {
       count += 1;
  }
  return count;
}

public str getRiskProfileVolume(int lines) {
	// catagorize the project volume risk (for java projects), taken from: 
	// I. Heitlager, T. Kuipers, and J. Visser. A practical model for measuring maintainability. 
	// In Proceedings of the 6th International Conference on Quality of Information and Communications Technology, 
	// QUATIC ’07, pages 30–39, Washington, DC, USA, 2007. IEEE Computer Society.
	if (lines > 1310000) return "very high"; 
	if (lines > 655000)  return "high";
	if (lines > 246000)  return "moderate";
	if (lines > 66000)   return "low";
	if (lines <= 66000)  return "very low";
	return "";
}

public int getRiskULOC(int size) {
	// catagorize the unit size risk, numbers taken from: 
	// Visser, J., Rigal, S., van der Leek, R., van Eck, P., & Wijnholds, G. (2016). 
	// Building Maintainable Software, Java Edition: Ten Guidelines for Future-Proof Code. 
	// " O'Reilly Media, Inc.". 
	if (size > 60)  return 4; 
	if (size > 30)  return 3;
	if (size > 15)  return 2;
	if (size <= 15) return 1;
	return 0;
}

public int getRiskCC(int complexity) {
	// catagorize the unit complexity risk, numbers taken from: 
	// I. Heitlager, T. Kuipers, and J. Visser. A practical model for measuring maintainability. 
	// In Proceedings of the 6th International Conference on Quality of Information and Communications Technology, 
	// QUATIC ’07, pages 30–39, Washington, DC, USA, 2007. IEEE Computer Society.
	if (complexity > 50)  return 4; 
	if (complexity > 20)  return 3;
	if (complexity > 10)  return 2;
	if (complexity <= 10) return 1;
	return 0;
}

public bool decreasing(tuple[&a, num] x, tuple[&a, num] y) {
   return x[1] > y[1];
}

public RiskProfile getRiskProfileULOC(list[MethodStat] ps) {
	int tot_low = 0, tot_mod = 0, tot_high = 0, tot_very_high = 0;
	for (a <- ps) {
		if (a.risk_size == 1) tot_low += a.size;
		if (a.risk_size == 2) tot_mod += a.size;
		if (a.risk_size == 3) tot_high += a.size;
		if (a.risk_size == 4) tot_very_high += a.size;
	};
	return <tot_low, tot_mod, tot_high, tot_very_high>;
}

public RiskProfile getRiskProfileCC(list[MethodStat] ps) {
	int tot_low = 0, tot_mod = 0, tot_high = 0, tot_very_high = 0;
	for (a <- ps) {
		if (a.risk_cc == 1) tot_low += a.size;
		if (a.risk_cc == 2) tot_mod += a.size;
		if (a.risk_cc == 3) tot_high += a.size;
		if (a.risk_cc == 4) tot_very_high += a.size;
	};
	return <tot_low, tot_mod, tot_high, tot_very_high>;
}

public void displayProfile(RiskProfile rp, int LOC) {
	println("        - low risk           : <(rp.low*100)/LOC>%");
	println("        - moderate risk      : <(rp.moderate*100)/LOC>%");
	println("        - high risk          : <(rp.high*100)/LOC>%");
	println("        - very high risk     : <(rp.very_high*100)/LOC>%");
}

// datatype to hold statistics on project methods
alias MethodStat = tuple[loc name, int size, int complexity, int tests, int risk_size, int risk_cc];
alias RiskProfile = tuple[int low, int moderate, int high, int very_high];

public void main(loc project) {

	// list containing all project statistics
	list[MethodStat] ProjectStat = [];
	
	// for each project method calculate the LOC, cyclomatic complexity and the risk catagory
	for (<name, b> <- toList(readMethods(project))) {
		int size = countLOC(b);
		int complexity = countComplexity(b);
		int tests = countAssert(b);
		int risk_size = getRiskULOC(size);
		int risk_cc = getRiskCC(complexity);
		MethodStat ms = <name, size, complexity, tests, risk_size, risk_cc>;
		//println("size: <ms.size> (<ms.risk_size>) compexity: <ms.complexity> (<ms.risk_cc>)");
		ProjectStat += ms;
	}
	
	// total LOC in project
	tot_LOC = sum(ProjectStat.size);

	println("======= Software Metrics Summary ======");
	println("Project name (methods)       : <project> (<size(ProjectStat.name)>)");
	println("Project volume (LOC)         : <tot_LOC> (<getRiskProfileVolume(tot_LOC)>)");
	println("Project unit tests (asserts) : <sum(ProjectStat.tests)> (<(sum(ProjectStat.tests)*100)/size(ProjectStat.name)>%)");
	
	// calculate quality profile for unit size
	RiskProfile ULOC_prof = getRiskProfileULOC(ProjectStat);
	println("Project unit size");
	displayProfile(ULOC_prof, tot_LOC);
	
	// calculate quality profile for unit complexity
	RiskProfile CC_prof = getRiskProfileCC(ProjectStat);
	println("Project unit complexity");
	displayProfile(CC_prof, tot_LOC);
	
	println("======= ======= ====== ======= ========");
	
	// todo: add quality profile for LOC metric
	// todo: add assert counting for unit tests (int unit_test = countAssert(b);)
	// todo: add code duplictation detecion metric
	
	// dump all project methods to stdout
	// printMethods(project);
}
