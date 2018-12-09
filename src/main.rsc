module main

import IO;
import Set;
import Relation;
import Map;
import List;
import String;
import util::Resources;
import lang::java::jdt::m3::Core;
import util::Benchmark;

import qprofile;
import metrics;

// read the project into M3 model
// returns a map of (location:methods (as string))
public map[loc, str] readMethods(loc project) {
	M3 model = createM3FromEclipseProject(project);
	return (a:readFile(a) | a <- methods(model));
}

// return the largest tuple based on size 
public bool increasing(tuple[loc name, int size, int complexity, int tests, int risk_size, int risk_cc] x, tuple[loc name, int size, int complexity, int tests, int risk_size, int risk_cc] y ) {
	return x.size > y.size;
}

public void main(loc project) {

	// list containing all project statistics
	list[MethodStat] ProjectStat = [];
	
	// list containing all lines of code in the project
	list[str] ProjectCodeList = [];
	
	// size of code duplication block (6 lines)
	int threshold = 6;
	
	// start clock
	int tstart = realTime();

	// calculate total lines of code (LOC) in project
	int tot_LOC = getProjectLOC(project);
	
	// add (clean) lines of source code to project code listing
	ProjectCodeList = getProjectCodeListing(project);
	
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
	}
	
	// generate a hashed code listing (for faster searching?)
	//println("hashing source code list..");
	//list[int] ProjectCodeList_hashed = mapper(ProjectCodeList, getHash);
	
	// calculate code duplication
	println("calculating code duplication..");
	int tdup = countDuplication(ProjectCodeList, threshold);
	println("found <tdup> lines of duplicates in <tot_LOC> lines");
	
	// list sorted on method size
	//list[MethodStat] ProjectStat_sorted_loc = sort(ProjectStat, increasing);
	//int max = 20;
	//println("Listing top <max> units (unit size): ");
	//for (i <- [0..max]) {
	//	println("method name     : <ProjectStat_sorted_loc[i].name>");
	//	println("size:complexity : <ProjectStat_sorted_loc[i].size>:<ProjectStat_sorted_loc[i].complexity>");
	//}
	
	// stop clock
	int tstop = realTime();

 	println("total evaluation time <(tstop-tstart)> msec");

	println("======= Software Metrics Summary ============");
	println("Project name             : <project>");
	println(" - number of files       : <getProjectFiles(project)>");
	println(" - number of methods     : <size(ProjectStat.name)>");
	println(" - volume (LOC)          : <tot_LOC> lines (<getRiskRatingVolume(tot_LOC)>)");
	
	// code duplication profile
	println(" - code duplication      : <tdup> lines, <(tdup*100)/tot_LOC>% (<getRiskRatingDuplication((tdup*100)/tot_LOC)>)");
	
	// unit testing profile
	println(" - unit tests (asserts)  : <sum(ProjectStat.tests)> lines, <(sum(ProjectStat.tests)*100)/sum(ProjectStat.complexity)>% (<getRiskRatingUnitTests((sum(ProjectStat.tests)*100)/sum(ProjectStat.complexity))>)");
	
	// quality profile for unit size
	RiskProfile ULOC_prof = getRiskProfileUnitLOC(ProjectStat);
	println(" - unit size             : (<getRiskRatingUnitSize(ULOC_prof)>)");
	displayProfile(ULOC_prof, sum(ProjectStat.size));
	
	// quality profile for unit complexity
	RiskProfile CC_prof = getRiskProfileCC(ProjectStat);
	println(" - unit complexity       : (<getRiskRatingComplexity(CC_prof)>)");
	displayProfile(CC_prof, sum(ProjectStat.size));
		
	// map individual metric ratings to a system score
	SystemScore ss = getSystemScore(getRisk(getRiskRatingVolume(tot_LOC)), getRisk(getRiskRatingDuplication((tdup*100)/tot_LOC)), 
		getRisk(getRiskRatingComplexity(CC_prof)), getRisk(getRiskRatingUnitSize(ULOC_prof)), 
		getRisk(getRiskRatingUnitTests((sum(ProjectStat.tests)*100)/sum(ProjectStat.complexity)))); 
	
	println("======= ISO 9126 System Level Scores =======");
	println(" - analysability         : <ss.analysability>");
	println(" - changeability         : <ss.changeability>");
	println(" - stability             : <ss.stability>");
	println(" - testability           : <ss.testability>");
	println("============================================");
}
