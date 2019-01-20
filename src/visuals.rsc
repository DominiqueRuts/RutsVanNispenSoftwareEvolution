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

import IO;

// main function to build up and display the high level project information
public void displayDashboard(ProjectSummary psum) {
	str pname = psum.projectname + "-dashboard";
	Figure top    = getTop(psum);
	Figure middle_t = getMiddleTop(); 
	Figure middle_b = getMiddleBottom(psum);
	//Figure bottom = getBottom(psum);
	
	Figure bottom = box(vshrink(0.45), fillColor("white"));
	
	render(pname, vcat([top, middle_t, middle_b, bottom]));
}

public Figure getTop(ProjectSummary psum) {
	str pname = "Project Overview \'" +  psum.projectname + "\'";	
	Figure b1  = box( text(pname, fontSize(20), fontBold(true)) );
	Figure b2a = box( text("Overall Rating", fontSize(20), fontBold(true)) );
	Figure b2b = getRating(psum.total_rating);
	Figure b2  = box( hcat([b2a, b2b]) );
	
	return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"));
	//return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"), std(lineColor("white")));
}

public Figure getMiddleTop() {	
	Figure b1 = box( text("Code Metrics", fontSize(20)) );
	Figure b2 = box( text("ISO9126 Quality Rating", fontSize(20)) );
	
	return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"));
	//return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"), std(lineColor("white")));
}

public Figure getMiddleBottom(ProjectSummary psum) {
	Figure b1 = getMetrics(psum);
	Figure b2 = getQualityRating(psum);
	
	return box(hcat([b1, b2]), vshrink(0.35), fillColor("white"));
	//return box(hcat([b1, b2]), vshrink(0.35), fillColor("white"), std(lineColor("white")));
}

public Figure getBottom(ProjectSummary psum) {
	
	return box(hcat[left, center, right]);
}

public Figure getMetrics(ProjectSummary psum) {
	Figure vola = box( text("Volume", fontSize(15)) );
	Figure volb = getRating(psum.vol_rating);
	Figure vol  = box( hcat([vola, volb]) );

	Figure dupa = box( text("Code Duplication", fontSize(15)) );
	Figure dupb = getRating(psum.dup_rating);
	Figure dup  = box( hcat([dupa, dupb]) );

	Figure sizea = box( text("Unit Size", fontSize(15)) );
	Figure sizeb = getRating(psum.size_rating);
	Figure size  = box( hcat([sizea, sizeb]) );

	Figure cca = box( text("Unit Complexity", fontSize(15)) );
	Figure ccb = getRating(psum.cc_rating);
	Figure cc  = box( hcat([cca, ccb]) );

	return box(vcat([vol, dup, size, cc]));
}

public Figure getQualityRating(ProjectSummary psum) {
	Figure anaa = box( text("Analysability", fontSize(15)) );
	Figure anab = getRating(psum.analysability);
	Figure ana  = box( hcat([anaa, anab]) );

	Figure chana = box( text("Changability", fontSize(15)) );
	Figure chanb = getRating(psum.changability);
	Figure chan  = box( hcat([chana, chanb]) );

	Figure staba = box( text("Stability", fontSize(15)) );
	Figure stabb = getRating(psum.stability);
	Figure stab  = box( hcat([staba, stabb]) );

	Figure tesa = box( text("Testability", fontSize(15)) );
	Figure tesb = getRating(psum.testability);
	Figure tes  = box( hcat([tesa, tesb]) );

	return box(vcat([ana, chan, stab, tes]));
}

public Figure getRating(int rating) {
	str col = "white", rcol = "white";
	list[Figure] l = [];
	
	if (rating == 1) rcol = "DarkRed";
	if (rating == 2) rcol = "Red";
	if (rating == 3) rcol = "Orange";
	if (rating == 4) rcol = "Yellow";
	if (rating == 5) rcol = "Green";
	
	for (a <- [0..5]) {
		if ((a+1) == rating) {
			col = rcol;
		}
		else {
			col = "white";
		}
		l += ellipse(fillColor(col), lineColor("black"), size(20), resizable(false, false)); 
	}
	return box(hcat(l), center());
}

public void visualize(list[MethodStat] ProjectStat_sorted_loc) {
	println("Start visualization...");
	cscale = colorScale(ProjectStat_sorted_loc.complexity, color("green", 0.5), color("red", 0.8));
	//list[loc] names = ProjectStat_sorted_loc.name;	
	t = treemap([
	     box(area(s.size),fillColor(cscale(s.complexity)),popup("Object: <s.name> \nSize: <s.size> \nComplexity: <s.complexity>")

//onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) { 
//                                                 println("<ProjectStat_sorted_loc[i].name> - Size: <s.size> - Complexity: <s.complexity>"); 
//                                                 return true;
//                                             } )
                         )  | s <- ProjectStat_sorted_loc, s.complexity > 2 //, i <- [0..size(ProjectStat_sorted_loc)]
     ] );
	render(t);
	println("End visualization...");
}

FProperty popup(str S){
 return mouseOver(box(text(S), size(50), fillColor("lightyellow"),
 grow(1.2),resizable(false)));
}