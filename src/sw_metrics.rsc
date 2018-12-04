module sw_metrics

import IO;
import Set;
import Relation;
import Map;
import List;
import String;
import util::Resources;
import lang::java::jdt::m3::Core;

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

// count the number of asserts in the string
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
	if (lines > 1310000) return "--"; 
	if (lines > 655000)  return "-";
	if (lines > 246000)  return "o";
	if (lines > 66000)   return "+";
	if (lines <= 66000)  return "++";
	return "";
}

public str getRiskProfileDuplication(int percent) {
	// catagorize the project code duplication risk, taken from: 
	// I. Heitlager, T. Kuipers, and J. Visser. A practical model for measuring maintainability. 
	// In Proceedings of the 6th International Conference on Quality of Information and Communications Technology, 
	// QUATIC ’07, pages 30–39, Washington, DC, USA, 2007. IEEE Computer Society.
	if (percent > 20) return "--"; 
	if (percent > 10)  return "-";
	if (percent > 5)  return "o";
	if (percent > 3)   return "+";
	if (percent <= 3)  return "++";
	return "";
}

public str getRiskProfileUnitTests(int percent) {
	// catagorize the project unit testing risk, taken from: 
	// I. Heitlager, T. Kuipers, and J. Visser. A practical model for measuring maintainability. 
	// In Proceedings of the 6th International Conference on Quality of Information and Communications Technology, 
	// QUATIC ’07, pages 30–39, Washington, DC, USA, 2007. IEEE Computer Society.
	if (percent < 20) return "--"; 
	if (percent < 60)  return "-";
	if (percent < 80)  return "o";
	if (percent < 95)   return "+";
	if (percent >= 95)  return "++";
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
	println("        - low risk       : <(rp.low*100)/LOC>%");
	println("        - moderate risk  : <(rp.moderate*100)/LOC>%");
	println("        - high risk      : <(rp.high*100)/LOC>%");
	println("        - very high risk : <(rp.very_high*100)/LOC>%");
}

// returns a list with blank lines and comment lines removed
// only returns a list when the clean list is > 6 LOC 
public list[str] cleanListing(list[str] dirtylist, int dsize) {
	list[str] cleanlist = [];
	for (a <- dirtylist) {
		// remove blank lines and comment lines from list
		if (!/^[\/\/]+/ := a && !/^[\s\t]*$/m := a) {
			cleanlist += a;
		}
	}
	// only return methods of (size >= dsize) lines of code  
	if (size(cleanlist) < dsize) {
		cleanlist = [];
	}
	return cleanlist;
}

// substring search (match individual lines in the project listing):
// search for pattern in the searchlist, advancing 1 line at a time until the end of the list
public int SearchForPattern(list[str] searchlist, list[str] pattern) {
	int hit = 0;
	int match = 0;
	for (i <- [0..(size(searchlist)-size(pattern)+1)]) {
		for (j <- [0..size(pattern)]) {
			if ( !contains(searchlist[i+j], pattern[j]) ) {
				break;
			}
			hit += 1;
		}
		// if a match is found, skip patternsize and continue
		if (hit == size(pattern)) {
			match += 1;
			i += size(pattern);
		}
		hit = 0;
	}
	return match;
}

public int countDuplication(list[str] listing, int blocksize) {
	int dup_tot = 0;
	for (i <- [0..(size(listing) - blocksize + 1)], i % blocksize == 0) {
		list[str] pattern = [a | a <- listing[i..(i+blocksize)]];
		int match = SearchForPattern(listing, pattern);
		if (match > 1) {
			//println("match:<match> at line i:<i>");
			dup_tot += (match - 1) * blocksize;
		}
		if (i % 100 == 0) println("   ..<(i*100)/size(listing)>%");
	}
	return dup_tot;
}

// datatype to hold statistics on project methods
alias MethodStat = tuple[loc name, int size, int complexity, int tests, int risk_size, int risk_cc];
alias RiskProfile = tuple[int low, int moderate, int high, int very_high];

public void main(loc project) {

	// list containing all project statistics
	list[MethodStat] ProjectStat = [];
	
	// list containing all lines of code in the project
	list[str] ProjectList = [];
	
	// size of code duplication block (6 lines)
	int dsize = 6;
	int tdup = 0;
	
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
		
		// add lines of code from methods to project code listing
		ProjectList += cleanListing(split("\n", b), dsize);
	}
	
	// calculate code duplication
	//println(" - projectsize: <size(ProjectList)>");
	println("calculating code duplication (please wait)");
	tdup = countDuplication(ProjectList, dsize);
	
	// total LOC in project
	tot_LOC = sum(ProjectStat.size);

	println("======= Software Metrics Summary ============");
	println("Project name             : <project>");
	println(" - number of methods     : <size(ProjectStat.name)>");
	println(" - volume (LOC)          : <tot_LOC> (<getRiskProfileVolume(tot_LOC)>)");
	
	// code duplication profile
	println(" - code duplication      : <(tdup*100)/size(ProjectList)>% (<getRiskProfileDuplication((tdup*100)/size(ProjectList))>)");
	
	// unit testing profile
	println(" - unit tests (asserts)  : <(sum(ProjectStat.tests)*100)/size(ProjectStat.name)>% (<getRiskProfileUnitTests((sum(ProjectStat.tests)*100)/size(ProjectStat.name))>)");
	
	// quality profile for unit size
	RiskProfile ULOC_prof = getRiskProfileULOC(ProjectStat);
	println(" - unit size");
	displayProfile(ULOC_prof, tot_LOC);
	
	// quality profile for unit complexity
	RiskProfile CC_prof = getRiskProfileCC(ProjectStat);
	println(" - unit complexity");
	displayProfile(CC_prof, tot_LOC);
	
	println("======= ======= ====== ======= ======= =======");
}
