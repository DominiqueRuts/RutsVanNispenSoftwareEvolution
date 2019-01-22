/*
 * course : Software Evolution (IM0202) Assignment 2: Software Visualization
 * authors: Johan van Nispen (836541627) and Dominique Ruts (852059122)
 * date   : 18/01/2019
 */

module visuals

import List;
import qprofile;
import metrics;
import vis::Figure;
import vis::Render;
import vis::KeySym;

import Relation;
import String;
import Map;
import Set;

import util::Math;
import IO;

public void visualize(list[MethodStat] ProjectStat_sorted_loc) {
	println("Start visualization...");
	ProjectFilesStats pfsRender = getProjectFileStats(ProjectStat_sorted_loc);
	cscale = colorScale(pfsRender.complexity, color("green", 0.5), color("red", 0.8));
	//list[loc] names = ProjectStat_sorted_loc.name;	
	t = treemap([
	     box(area(s.size),fillColor(cscale(s.complexity)),popup("Object: <s.file> \nSize: <s.size> \nComplexity: <s.complexity>")

//onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) { 
//                                                 println("<ProjectStat_sorted_loc[i].name> - Size: <s.size> - Complexity: <s.complexity>"); 
//                                                 return true;
//                                             } )
                         )  | s <- pfsRender, s.complexity > 2 //, i <- [0..size(ProjectStat_sorted_loc)]
     ] );
	//render(t);
	//render(scaledbox(max(pfsRender.complexity), pfsRender));
	
	
	//e1 = circles(ProjectStat_sorted_loc);
	e1 = circles(pfsRender);
	
	//render(e1);
	render("Complexity view", scaledCircles(pfsRender));
	
	println("End visualization...");
}

FProperty popup(str s){
 return mouseOver(box(text(s), size(50), fillColor("lightyellow"),
 grow(1.2),resizable(false)));
}

//Figure circles(list[MethodStat] ProjectStat_sorted_loc){
Figure circles(ProjectFilesStats ProjectStat_sorted_loc){
	ProjectFilesStat mFirst = head(ProjectStat_sorted_loc);
	
 return box(overlay([ellipse(width(toReal(s.complexity)/2), height(toReal(s.complexity)/2), align(toReal(s.size)/mFirst.size,1-toReal(s.complexity)/545), fillColor(color("blue", 0.6)),resizable(false),popup("Object: <s.file> \nSize: <s.size> \nComplexity: <s.complexity>")) | s <- ProjectStat_sorted_loc]),size(toReal(mFirst.size)*2,toReal(545)*2)) ;
}

Figure scaledbox(int maxComplexity, ProjectFilesStats pf){
   int n = 1;
   cscale = colorScale(pf.complexity, color("green", 0.5), color("red", 0.8));
   return vcat([ hcat([ scaleSlider(int() { return 1; },     
                                    int () { return maxComplexity; },  
                                    int () { return n; },    
                                    void (int s) { n = s; }, 
                                    width(500)),
                        text(str () { return "Minimum complexity: <n>";})
                      ], left(),  top(), resizable(false)),  
                 computeFigure(Figure (){ return treemap([box(area(s.size),fillColor(cscale(s.complexity)),popup("File: <s.file> \nSize: <s.size> \nComplexity: <s.complexity>"))  | s <- pf, s.complexity > n-1] ); })
               ]);
}

private real maxComplexityLog = 0.0;

Figure scaledCircles(ProjectFilesStats pf){
	ProjectFilesStat mFirst = head(pf);
	int maxMethodCount = max(pf.methodCount);
	int maxComplexity = max(pf.complexity);
	maxComplexityLog = log(maxComplexity,2);

   //int n = 1;
   return vcat([ text("Complexity distribution per Java file"),
   			hcat ([text("Method count", textAngle(270)),
   				
   				vcat([ hcat([ text(str () { return "Minimum complexity:";}),
   				 				scaleSlider(int() { return 1; },     
                                    int () { return maxComplexity; },  
                                    int () { return complexityFilter; },    
                                    void (int s) { complexityFilter = s; }, 
                                    width(500)),
                                    complexityfield()
                       
                      ], left(),  top(), resizable(false)),  
                      hcat([grid([[box(text("<g>"),height(30),resizable(false), bottom(),lineWidth(0))] | g <- [maxMethodCount..0], remainder(toRat(g,20)) == 0], vgap(30)),
                      vcat([computeFigure(Figure (){ return box(overlay([createEllipse(mFirst, maxMethodCount, maxComplexity, s) | s <- pf, s.complexity > complexityFilter-1, s.maxriskcc == getVeryHighRisk() || s.maxriskcc == getHighRisk() || s.maxriskcc == getModerateRisk() || s.maxriskcc == getLowRisk() || getDefaultRisk() == 0])); }), //,size(toReal(mFirst.size)*2,toReal(545)*2)); })
                      grid([[box(text("|\n<toInt(pow(2,round(g)))>",ialign(0.5)),height(30),gap(5),resizable(false), left(),lineWidth(0)) | g <- [0.. log(mFirst.size,2)]]]),
              			 text("Size (Lines of Code)")
                      ],gap(2)),
                      vcat([check(),
                      fileDetails()])
                      ], top())
                 
               ])
               ])
               ]);
}




Figure createEllipse(ProjectFilesStat mFirst, int maxMethodCount, int maxComplexity, ProjectFilesStat s) {
	return ellipse(size(log(s.complexity*2,2)/maxComplexityLog*40), align(log(s.size,2)/log(mFirst.size, 2),1-toReal(s.methodCount)/maxMethodCount),  fillColor(getRiskColor(s.maxriskcc)),resizable(false),popup(ellipsePopupText(s)));
}

public int getDefaultRisk() {
	if (veryHighRisk)  return 4; 
	if (highRisk)  return 3;
	if (moderateRisk)  return 2;
	if (lowRisk) return 1;
	return 0;
}

public int getVeryHighRisk() {
	if (veryHighRisk)  return 4; 
	return 0;
}

public int getHighRisk() {
	if (highRisk)  return 3; 
	return 0;
}

public int getModerateRisk() {
	if (moderateRisk)  return 2; 
	return 0;
}

public int getLowRisk() {
	if (lowRisk)  return 1; 
	return 0;
}

public Color getRiskColor(int risk) {
	if (risk == 4)  return color("red",0.6); 
	if (risk == 3)  return color("orange",0.6);
	if (risk == 2)  return color("yellow",0.6);
	if (risk == 1) return color("green",0.6);
	return color("grey");
}

private bool veryHighRisk = false;
private bool highRisk = false;
private bool moderateRisk = false;
private bool lowRisk = false;

public Figure check(){
  bool state = false;
  return vcat([ text("Filter risk level:"),
  				checkbox("4 - Very High Risk", void(bool s4){ state = s4; if(s4) {veryHighRisk = true; } else {veryHighRisk = false;}}),
  				checkbox("3 - High Risk", void(bool s3){ state = s3; if(s3) {highRisk = true; } else {highRisk = false;}}),
  				checkbox("2 - Moderate Risk", void(bool s2){ state = s2; if(s2) {moderateRisk = true; } else {moderateRisk = false;}}),
  				checkbox("1 - Low Risk", void(bool s1){ state = s1; if(s1) {lowRisk = true; } else {lowRisk = false;}})
              ], width(100), resizable(false));
}

public Figure fileDetails(){
  bool state = false;
  return vcat([ text("File details"),
  				text("Name:"),
  				text("Path:")
              ], width(100), resizable(false));
}

private int complexityFilter = 1;

public Figure complexityfield(){
  return vcat([ box(textfield("<complexityFilter>", void(str s){ complexityFilter = toInt(s);}, fillColor("yellow")), fillColor("yellow"),width(50), resizable(false))
              ]);
}  

private str ellipsePopupText(ProjectFilesStat s) {
	return "Object: <s.file> \nLines of Code: <s.size> \nComplexity: <s.complexity> \nMethods: <s.methodCount>";
}

alias ProjectFilesStats = list[tuple[str file, int size, int complexity, int methodCount, int riskcc, int maxriskcc]];
alias ProjectFilesStat = tuple[str file, int size, int complexity, int methodCount, int riskcc, int maxriskcc];
alias ProjectFilesSize = map[str file, int size];
alias ProjectFilesMethods = map[str file, int methods];
alias ProjectFilesRiskCC = map[str file, int riskCC];
alias ProjectFilesMaxRiskCC = map[str file, int maxriskcc];
alias ProjectFilesComplexity = map[str file, int complexity];

private ProjectFilesStats getProjectFileStats(list[MethodStat] ProjectStat_sorted_loc) {
	ProjectFilesStats pfs = [];
	ProjectFilesSize pfsize = ();
	ProjectFilesMethods pfmethods = ();
	ProjectFilesRiskCC pfriskcc = ();
	ProjectFilesMaxRiskCC pfmaxriskcc = ();
	ProjectFilesComplexity pfcomplexity = ();
	
	for (s <- ProjectStat_sorted_loc) {
		if(getFileName(s.name) in pfsize) {			
			pfsize[getFileName(s.name)] = pfsize[getFileName(s.name)] + s.size;
			pfmethods[getFileName(s.name)] += 1;
			pfriskcc[getFileName(s.name)] += s.risk_cc;			
			pfmaxriskcc[getFileName(s.name)] =  pfmaxriskcc[getFileName(s.name)] > s.risk_cc ? pfmaxriskcc[getFileName(s.name)] : s.risk_cc;
			pfcomplexity[getFileName(s.name)] = pfcomplexity[getFileName(s.name)] + s.complexity;
		} else {
			pfsize[getFileName(s.name)] = s.size;
			pfmethods[getFileName(s.name)] = 1;
			pfriskcc[getFileName(s.name)] = s.risk_cc;
			pfmaxriskcc[getFileName(s.name)] = s.risk_cc;
			pfcomplexity[getFileName(s.name)] = s.complexity;
		}
	}
	
	for (pf <- pfsize) {
		pfs += <pf, pfsize[pf], pfcomplexity[pf], pfmethods[pf], pfriskcc[pf], pfmaxriskcc[pf]>;
	}
	
	pfs = sort(pfs, increasing2);
	
 return pfs;
}

public bool increasing2(tuple[str name, int size, int complexity, int methodCount, int riskcc, int maxriskcc] x, tuple[str name, int size, int complexity, int methodCount, int riskcc, int maxriskcc] y ) {
	return x.size > y.size;
}


private str getFileName(loc s) {
	str inputString = s.path;
	int lastSlash = findLast(inputString, "/");
	str sToDisplay = substring(inputString, 0, lastSlash);
	sToDisplay = substring(sToDisplay, findLast(sToDisplay, "/")+1);
	
	return sToDisplay;
}

private str clearString(loc s) {
	str inputString = s.path;
	int lastSlash = findLast(inputString, "/");
	str sToDisplay = substring(inputString, lastSlash+1);
	sToDisplay = substring(sToDisplay, 0, findFirst(sToDisplay, "("));
	
	return sToDisplay;
}