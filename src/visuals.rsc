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
	render(scaledCircles(max(pfsRender.complexity), pfsRender));
	
	
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

Figure scaledCircles(int maxComplexity, ProjectFilesStats pf){
	ProjectFilesStat mFirst = head(pf);
   int n = 1;
   return vcat([ text("Complexity distribution per Java file"),
   			hcat ([text("Complexity"),
   				grid([[box(text("<g>"),height(30),resizable(false), left(),lineWidth(0))] | g <- [max(pf.complexity)..0], remainder(toRat(g,50)) == 0]),
   				vcat([ hcat([ text(str () { return "Minimum complexity filter: <n>";}),
   				 				scaleSlider(int() { return 1; },     
                                    int () { return maxComplexity; },  
                                    int () { return n; },    
                                    void (int s) { n = s; }, 
                                    width(500))
                       
                      ], left(),  top(), resizable(false)),  
                 computeFigure(Figure (){ return box(overlay([ellipse(width(toReal(s.complexity)/2), height(toReal(s.complexity)/2), align(toReal(s.size)/mFirst.size,1-toReal(s.complexity)/545), fillColor(color("blue", 0.6)),resizable(false),popup("Object: <s.file> \nSize: <s.size> \nComplexity: <s.complexity>")) | s <- pf, s.complexity > n-1])); }) //,size(toReal(mFirst.size)*2,toReal(545)*2)); })
               , grid([[box(text("<g>"),height(30),resizable(false), left(),lineWidth(0)) | g <- [0..mFirst.size], remainder(toRat(g,100)) == 0]]),
               text("Size")])
               ])
               ]);
}

//alias ProjectFilesStats = list[tuple[str file, str name, int size, int complexity]];
alias ProjectFilesStats = list[tuple[str file, int size, int complexity]];
alias ProjectFilesStat = tuple[str file, int size, int complexity];
alias ProjectFilesSize = map[str file, int size];
alias ProjectFilesComplexity = map[str file, int complexity];

private ProjectFilesStats getProjectFileStats(list[MethodStat] ProjectStat_sorted_loc) {
	ProjectFilesStats pfs = [];
	ProjectFilesSize pfsize = ();
	ProjectFilesComplexity pfcomplexity = ();
	
	for (s <- ProjectStat_sorted_loc) {
		//pfs += <getFileName(s.name), clearString(s.name), s.size, s.complexity>;
		if(getFileName(s.name) in pfsize) {			
			pfsize[getFileName(s.name)] = pfsize[getFileName(s.name)] + s.size;
			pfcomplexity[getFileName(s.name)] = pfcomplexity[getFileName(s.name)] + s.complexity;
		} else {
			pfsize[getFileName(s.name)] = s.size;
			pfcomplexity[getFileName(s.name)] = s.complexity;
		}
	}
	
	for (pf <- pfsize) {
		pfs += <pf, pfsize[pf], pfcomplexity[pf]>;
		//println("<pf> - <pfsize[pf]> - <pfcomplexity[pf]>");
	}
	
	pfs = sort(pfs, increasing2);
	
	//m = ();
	//for (pfs <- ProjectStat_sorted_loc) {
	//str f = getFileName(s.name);
  	// m[f]?[] += [s.size];
	//}
	//println(m);
 return pfs;
}

public bool increasing2(tuple[str name, int size, int complexity] x, tuple[str name, int size, int complexity] y ) {
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