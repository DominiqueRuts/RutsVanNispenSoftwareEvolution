module main

import IO;
import Set;
import Relation;
import Map;
import List;
import String;
import util::Benchmark;
import util::Resources;
import lang::java::jdt::m3::Core;

import qprofile;
import metrics;

// read the project into M3 model
// returns a map of (location:methods (as string))
public map[loc, str] readMethods(loc project) {
	M3 model = createM3FromEclipseProject(project);
	return (a:readFile(a) | a <- methods(model));
}

public void main(loc project) {

	// set startTime to define how long the calculation takes to complete
	int startTime = getNanoTime();

	// list containing all project statistics
	list[MethodStat] ProjectStat = [];
	
	// list containing all lines of code in the project
	list[str] ProjectList = [];
	
	// size of code duplication block (6 lines)
	int dsize = 6;
	int tdup = 0;
		
	// for each project method calculate the software metrics
	for (<name, b> <- toList(readMethods(project))) {
		int size = countLOC(name, b);         // calc number of lines of code in method (unit size)
		int complexity = countComplexity(b);  // calc the cyclomatic complexity (unit complexity)
		int tests = countAssert(b);           // calc the number of assert staements (unit testing)
		
		int risk_size = getRiskUnitLOC(size);
		int risk_cc = getRiskCC(complexity);
		
		MethodStat ms = <name, size, complexity, tests, risk_size, risk_cc>;
		//println("size: <ms.size> (<ms.risk_size>) compexity: <ms.complexity> (<ms.risk_cc>)");
		ProjectStat += ms;
		
		// add (clean) lines of code from the methods to project code listing
		ProjectList += cleanListing(split("\n", b), dsize);
	}
	
	// calculate code duplication
	println("projectsize (for code duplication): <size(ProjectList)>");
	println("calculating code duplication (please wait)");
	tdup = countDuplication(ProjectList, dsize);
	
	// total LOC in project
	tot_LOC = sum(ProjectStat.size);

	println("======= Software Metrics Summary ============");
	println("Project name             : <project>");
	println(" - number of methods     : <size(ProjectStat.name)>");
	println(" - volume (LOC)          : <tot_LOC> (<getRiskRatingVolume(tot_LOC)>)");
	
	// code duplication profile
	println(" - code duplication      : <(tdup*100)/size(ProjectList)>% (<getRiskRatingDuplication((tdup*100)/size(ProjectList))>)");
	
	// unit testing profile
	println(" - unit tests (asserts)  : <(sum(ProjectStat.tests)*100)/size(ProjectStat.name)>% (<getRiskRatingUnitTests((sum(ProjectStat.tests)*100)/size(ProjectStat.name))>)");
	
	// quality profile for unit size
	RiskProfile ULOC_prof = getRiskProfileUnitLOC(ProjectStat);
	println(" - unit size             : (<getRiskRatingUnitSize(ULOC_prof)>)");
	displayProfile(ULOC_prof, tot_LOC);
	
	// quality profile for unit complexity
	RiskProfile CC_prof = getRiskProfileCC(ProjectStat);
	println(" - unit complexity       : (<getRiskRatingComplexity(CC_prof)>)");
	displayProfile(CC_prof, tot_LOC);
	
	println("======= ======= ====== ======= ======= =======");
	
	// calculate the time it took to analyze the code 
	int estimatedTime = (getNanoTime() - startTime)/ 1000000000;
	
	println("Code analysis took <estimatedTime> seconds");
	
	println("======= ======= ====== ======= ======= =======");
}
