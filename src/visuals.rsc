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
import util::Resources;
import IO;

// defined types to hold visualization data
alias ProjectFilesStats = list[tuple[str file, str path, int size, int complexity, int methodCount, int riskcc, int maxriskcc]];
alias ProjectFilesStat = tuple[str file, str path, int size, int complexity, int methodCount, int riskcc, int maxriskcc];
alias ProjectFilesPath = map[str file, str path];
alias ProjectFilesSize = map[str file, int size];
alias ProjectFilesMethods = map[str file, int methods];
alias ProjectFilesRiskCC = map[str file, int riskCC];
alias ProjectFilesMaxRiskCC = map[str file, int maxriskcc];
alias ProjectFilesComplexity = map[str file, int complexity];

private int complexityFilter = 1;
private real maxComplexityLog = 0.0;
// private variables to identify which Risk CC checkbox is checked
private bool veryHighRisk = false;
private bool highRisk = false;
private bool moderateRisk = false;
private bool lowRisk = false;
// private variables to enable Accessibility mode
private bool colorblindview = false;
private str veryHighRiskStyle = "solid";
private str highRiskStyle = "solid";
private str moderateRiskStyle = "solid";
private str lowRiskStyle = "solid";
// private variable to hold the clicked bubble details
private ProjectFilesStat clickedFileStat = <"", "", 0, 0, 0, 0, 0>;
private ProjectFilesStats pfsRender = [];

public void visualize(list[MethodStat] ProjectStat_sorted_loc, str project) {
	println("Start visualization...");
	pfsRender = getProjectFileStats(ProjectStat_sorted_loc);
	cscale = colorScale(pfsRender.complexity, color("green", 0.5), color("red", 0.8));
	

	//render(scaledbox(max(pfsRender.complexity), pfsRender));
	render("ICicle view", scaledICicle(pfsRender, project));
	//render("Complexity view", scaledCircles(pfsRender));
	
	println("End visualization...");
}

FProperty popup(str s){
 return mouseOver(box(text(s), size(50), fillColor("lightyellow"),
 grow(1.2),resizable(false)));
}

FProperty ellipseMouseDown(ProjectFilesStat s) {
	return onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {                                                   
                                                 clickedFileStat = s;
                                                 return true; //fileName = fn;
                                             } );
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

data LevelMap = LevelMap(str name, list[LevelMap] children, int maxriskcc, int size);

Figure scaledICicle(ProjectFilesStats pf, str project){
	str toplevel = split("/",pf[0].path)[1];
	
	LevelMap lmp2 = readLoc("<project>/src");
	
	return vcat([
			text("Architectural view", fontSize(20), fontBold(true)),
					hcat([
						computeFigure(Figure (){ return LevelMapGrid(lmp2);}),
						vcat([
							check(),
							checkColorBlind()
						],resizable(false),top(),left(),gap(5))                   
					], top(),gap(2))     
		],gap(20));		

}

Figure LevelMapGrid(LevelMap lm) {
	return grid([[box(text(lm.name),top(),height(30))],[LevelMapItem(lm.children)]],top(),resizable(false));
}

Figure LevelMapItem(list[LevelMap] li) {
	list[value] lg = [];
	real colorT = 0.0;
	for (i <- li) {
		if (i.children == []) {
			lg+= grid([[box(width(sqrt(i.size)),height(100),top(),fillColor(getRiskColor(i.maxriskcc)),align(0),resizable(false))]] );
		} else {
			if (!isEmptyLevelMap(i[1])) {
				colorT += 0.1;
				lg+= grid([[box(text(substring(i.name,findLast(i.name,"/")+1),width(5),top(),textAngle(90)),width(5),top(),fillColor(color("blue",colorT)), size(10),align(0),resizable(true))],[LevelMapItem(i.children)]],resizable(false) );
			}
		}
	}
	
	return grid([lg]);
}

private bool isEmptyLevelMap(list[LevelMap] l) {
	if (isEmpty(l) || (isEmptyLevelMap(l[0].children)) && !endsWith("<l[0].name>",".java")) {
		return true; 
	} else {
		return false;
	}
}

private int maxSize = 0;

private LevelMap readLoc(str name) {
	loc lc = toLocation("project://<name>");
	println(lc);
	list[str] files = listEntries(lc);
	
	list[LevelMap] tmp = [];	
	
	for(f <- files) {
		str filePath = "<name>/<f>";
		if (isDirectory(toLocation("project://<filePath>"))) {
			tmp += readLoc(filePath);			
		} else if(isFile(toLocation("project://<filePath>")) && endsWith(filePath, ".java")) {
			str filteredName = substring(getFileName("<filePath>/"),0,findLast(getFileName("<filePath>/"),"."));
			int mrc = (size(domainR(pfmaxriskcc,{filteredName})) > 0 ? pfmaxriskcc[filteredName]: 1);			
			int size = (size(domainR(pfsize,{filteredName})) > 0 ? pfsize[filteredName]: 1);
			maxSize = size > maxSize ? size : maxSize;
			tmp += LevelMap(filePath, [], mrc, size);
		}
	}

	return LevelMap(name, tmp, 0, 0);
}


Figure scaledCircles(ProjectFilesStats pf){
	int maxFileSize = max(pf.size);
	int maxMethodCount = max(pf.methodCount);
	int maxComplexity = max(pf.complexity);
	maxComplexityLog = log(maxComplexity,2);

   return vcat([
			text("Complexity distribution", fontSize(20), fontBold(true)),
   			hcat ([
   				text("Method count", textAngle(270)),   				
   				vcat([
   					hcat([
   						text(str () { return "Minimum total complexity: <complexityFilter>";}),
   				 		createComplexitySlider(maxComplexity)//,
						//complexityfield()                       
					], left(),  top(), resizable(false)),  
					hcat([
						grid(
							[
								[createYAxis(maxMethodCount), createBubbleChart(maxFileSize, maxMethodCount, maxComplexity, pf)],
								[box(width(20),resizable(false), left()), createXAxis(maxFileSize)]						
						],resizable(true), left(), gap(2)),
						vcat([
							check(),
							checkColorBlind()
						],resizable(false),top(),left(),gap(5))                   
					], top(),gap(2))                
				],gap(2))
			]),text("Size (Lines of Code)"),computeFigure(Figure (){ return fileDetails();}) 
		],gap(20));
}

Figure createComplexitySlider(int max) {
	return scaleSlider(int() { return 1; },     
                                    int () { return max; },  
                                    int () { return complexityFilter; },    
                                    void (int s) { complexityFilter = s; }, 
                                    width(500));
}

Figure createXAxis(int max) {
	return grid([[box(text("|\n<toInt(pow(2,round(g)))>",ialign(0.5)),height(30),gap(1),resizable(false), left(),lineWidth(0)) | g <- [0.. log(max,2)]]]);
}

Figure createYAxis(int max) {
	return grid([[box(text("<g>-"),height(30),resizable(false), bottom(),lineWidth(0))] | g <- [max..0], remainder(toRat(g,20)) == 0], vgap(30),resizable(false), left());
}

Figure createBubbleChart(int maxFileSize, int maxMethodCount, int maxComplexity, ProjectFilesStats pf) {
	return computeFigure(Figure (){ return box(overlay([createEllipse(maxFileSize, maxMethodCount, maxComplexity, s) | s <- pf, s.complexity > complexityFilter-1, s.maxriskcc == getVeryHighRisk() || s.maxriskcc == getHighRisk() || s.maxriskcc == getModerateRisk() || s.maxriskcc == getLowRisk() || getDefaultRisk() == 0])); });
}

Figure createEllipse(int maxFileSize, int maxMethodCount, int maxComplexity, ProjectFilesStat s) {
	return ellipse(size(sqrt(s.complexity)*3), align(log(s.size,2)/log(maxFileSize, 2),1-toReal(s.methodCount)/maxMethodCount),  fillColor(getRiskColor(s.maxriskcc)),lineStyle(getRiskLineStyle(s.maxriskcc)),lineWidth(getRiskLineWidth(s.maxriskcc)),resizable(false),ellipseMouseDown(s));
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


public Figure check(){
  bool state = false;
  return vcat([ text("Filter CC risk level:",left(), width(150)),
  				checkbox("4 - Very High Risk", void(bool s4){ state = s4; if(s4) {veryHighRisk = true; } else {veryHighRisk = false;}},fillColor("red"),left(), width(150), resizable(false)),
  				checkbox("3 - High Risk", void(bool s3){ state = s3; if(s3) {highRisk = true; } else {highRisk = false;}},fillColor("orange"),left(), width(150), resizable(false)),
  				checkbox("2 - Moderate Risk", void(bool s2){ state = s2; if(s2) {moderateRisk = true; } else {moderateRisk = false;}},fillColor("yellow"),left(), width(150), resizable(false)),
  				checkbox("1 - Low Risk", void(bool s1){ state = s1; if(s1) {lowRisk = true; } else {lowRisk = false;}},fillColor("green"),left(), width(150), resizable(false))
              ], width(150), resizable(false),top());
}

public str getRiskLineStyle(int risk) {
	if (risk == 4)  return veryHighRiskStyle; 
	if (risk == 3)  return highRiskStyle;
	if (risk == 2)  return moderateRiskStyle;
	if (risk == 1) return lowRiskStyle;
	return "solid";
}

public int getRiskLineWidth(int risk) {
	return colorblindview ? risk : 1;
}



public Figure checkColorBlind(){
  bool colorblind = false;
  return vcat([  text("Accessibility:",left(), width(150)),				
  				checkbox("Color blind?", void(bool s){ colorblind = s; if(s) {colorblindview = true;veryHighRiskStyle = "dashdot";highRiskStyle = "dash";moderateRiskStyle = "dot";lowRiskStyle = "solid"; } else {colorblindview = false;veryHighRiskStyle = "solid";highRiskStyle = "solid";moderateRiskStyle = "solid";lowRiskStyle = "solid";}},left(), width(150), resizable(false))
              ], width(150), resizable(false),top());
}



public Figure fileDetails(){
  bool state = false;
  return grid([[text("File details",left(),top(),width(150),fontBold(true)),grid([[
  				text("Name:",left(),ialign(0),width(250)),
  				text("<clickedFileStat.file>",left()),
  				text("Path:",left(),width(250)),
  				text("<clickedFileStat.path>",left())],
  				[text("Max. CC Risk Level:",left(),width(250)),
  				text("<clickedFileStat.maxriskcc == 0 ? "" : clickedFileStat.maxriskcc>",left()),
  				text("Total Complexity (sum):",left(),width(250)),
  				text("<clickedFileStat.complexity == 0 ? "" : clickedFileStat.complexity>",left())],
  				[text("Number of methods:",left(),width(250)),
  				text("<clickedFileStat.methodCount == 0 ? "" : clickedFileStat.methodCount>",left()),
  				text("Lines of Code:",left(),width(250)),
  				text("<clickedFileStat.size>",left())
              ]],left(),width(750))
              ]],top(),left(),resizable(false));
}



public Figure complexityfield(){
  return vcat([ box(textfield("<complexityFilter>", void(str s){ complexityFilter = toInt(s);}, fillColor("yellow")), fillColor("yellow"),width(50), resizable(false))
              ]);
}  

private str ellipsePopupText(ProjectFilesStat s) {
	return "Object: <s.file> \nLines of Code: <s.size> \nComplexity: <s.complexity> \nMethods: <s.methodCount>";
}


ProjectFilesSize pfsize = ();
ProjectFilesMaxRiskCC pfmaxriskcc = ();

private ProjectFilesStats getProjectFileStats(list[MethodStat] ProjectStat_sorted_loc) {
	ProjectFilesStats pfs = [];
	ProjectFilesPath pfpath = ();
	pfsize = ();
	ProjectFilesMethods pfmethods = ();
	ProjectFilesRiskCC pfriskcc = ();
	pfmaxriskcc = ();
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
			pfpath[getFileName(s.name)] = getPath(s.name);
			pfmethods[getFileName(s.name)] = 1;
			pfriskcc[getFileName(s.name)] = s.risk_cc;
			pfmaxriskcc[getFileName(s.name)] = s.risk_cc;
			pfcomplexity[getFileName(s.name)] = s.complexity;
		}
		
		
	}
	
	for (pf <- pfsize) {
		pfs += <pf, pfpath[pf], pfsize[pf], pfcomplexity[pf], pfmethods[pf], pfriskcc[pf], pfmaxriskcc[pf]>;
	}
	
	
 return pfs;
}

private str getFileName(str s) {
	return getFileName(toLocation(s));
}

private str getFileName(loc s) {
	str inputString = s.path;
	int tmp = findFirst(inputString, "(");
	str sToDisplay = tmp > -1 ? substring(inputString, 0, tmp) : inputString;
	int lastSlash = findLast(sToDisplay, "/");
	sToDisplay = substring(sToDisplay, 0, lastSlash);
	sToDisplay = substring(sToDisplay, findLast(sToDisplay, "/")+1);
	
	return sToDisplay;
}

private str getPath(loc s) {
	str inputString = s.path;
	int tmp = findFirst(inputString, "(");
	str sToDisplay = tmp > -1 ? substring(inputString, 0, tmp) : inputString;
	int lastSlash = findLast(sToDisplay, "/");
	sToDisplay = substring(sToDisplay, 0, lastSlash+1);	
	return sToDisplay;
}