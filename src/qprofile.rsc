module qprofile

import IO;

// datatypes to hold statistics on project methods
alias MethodStat = tuple[loc name, int size, int complexity, int tests, int risk_size, int risk_cc];
alias RiskProfile = tuple[int low, int moderate, int high, int very_high];
alias SystemScore = tuple[str analysability, str changeability, str stability, str testability];

public str getRiskRatingVolume(int lines) {
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

public str getRiskRatingDuplication(int percent) {
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

public str getRiskRatingUnitTests(int percent) {
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

public str getRiskRatingComplexity(RiskProfile p) {
	// catagorize the project unit testing risk, taken from: 
	// I. Heitlager, T. Kuipers, and J. Visser. A practical model for measuring maintainability. 
	// In Proceedings of the 6th International Conference on Quality of Information and Communications Technology, 
	// QUATIC ’07, pages 30–39, Washington, DC, USA, 2007. IEEE Computer Society.
	if (p.moderate > 50 || p.high > 15 || p.very_high > 5) return "--"; 
	if (p.moderate > 40 || p.high > 10 || p.very_high > 0)  return "-";
	if (p.moderate > 30 || p.high > 5 || p.very_high > 0)  return "o";
	if (p.moderate > 25 || p.high > 0 || p.very_high > 0)   return "+";
	if (p.moderate <= 25 && p.high == 0 && p.very_high == 0)  return "++";
	return "";
}

public str getRiskRatingUnitSize(RiskProfile p) {
	// catagorize the project unit testing risk, taken from: 
	// I. Heitlager, T. Kuipers, and J. Visser. A practical model for measuring maintainability. 
	// In Proceedings of the 6th International Conference on Quality of Information and Communications Technology, 
	// QUATIC ’07, pages 30–39, Washington, DC, USA, 2007. IEEE Computer Society.
	if (p.moderate > 50 || p.high > 15 || p.very_high > 5) return "--"; 
	if (p.moderate > 40 || p.high > 10 || p.very_high > 0)  return "-";
	if (p.moderate > 30 || p.high > 5 || p.very_high > 0)  return "o";
	if (p.moderate > 25 || p.high > 0 || p.very_high > 0)   return "+";
	if (p.moderate <= 25 && p.high == 0 && p.very_high == 0)  return "++";
	return "";
}

// return risk from rating
public int getRisk(str rating) {
	if (rating == "--") return 1; 
	if (rating == "-")  return 2;
	if (rating == "o")  return 3;
	if (rating == "+")  return 4;
	if (rating == "++") return 5;
	// default
	return 0;
}

// return rating from risk
public str getScore(int risk) {
	if (risk == 1) return "--"; 
	if (risk == 2) return "-";
	if (risk == 3) return "o"; 
	if (risk == 4) return "+";
	if (risk == 5) return "++"; 
	return "";
}

public int getRiskUnitLOC(int size) {
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

public RiskProfile getRiskProfileUnitLOC(list[MethodStat] ps) {
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

public SystemScore getSystemScore(int volume, int duplication, int unit_cc, int unit_size, int unit_test) {
	//println("ratings - vol:<volume> dup:<duplication> cc:<unit_cc> size:<unit_size> test:<unit_test>");
	
	str analysability = getScore((volume + duplication + unit_size + unit_test)/4);
	str changeability = getScore((duplication + unit_cc)/2);
	str stability = getScore(unit_test);
	str testability = getScore((unit_cc + unit_size + unit_test)/3);
	
	return <analysability, changeability, stability, testability>;
}

public void displayProfile(RiskProfile rp, int LOC) {
	println("        - low risk       : <(rp.low*100)/LOC>%");
	println("        - moderate risk  : <(rp.moderate*100)/LOC>%");
	println("        - high risk      : <(rp.high*100)/LOC>%");
	println("        - very high risk : <(rp.very_high*100)/LOC>%");
}
