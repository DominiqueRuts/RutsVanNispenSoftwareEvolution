module metrics

import IO;
import Set;
import Relation;
import Map;
import List;
import String;

// count the Lines Of Code (LOC) in a string
public int countLOC(loc l, str s) {
  int count = 0;
  int bl = 0, cl = 0, ml = 0;
  
  // count the number of newline characters
  for (/[\n]+/ := s) {
       count += 1;
  }
  // number of blank lines
  for (/^[\s]*$/m := s) {
      bl += 1;
  }
  // number of comment lines (only lines with comments, not code and //)
  for (/^[\s]*[\/]{2}/ := s) {
  	   cl += 1;
  }
  // number of multiline comments
  for (/\/\*[^*]*\*+(?:[^\/*][^*]*\*+)*\// := s) {
  	  ml += 1;
  } 
  
  // LOC = newlines - (blank lines + comment lines + multicomment)
  count += (bl + cl + ml);
  if (count < 0) {
  	println("<l>: invalid #lines: <count>, blank(<bl>), comment(<cl>), multi-comment(<ml>)");
  }
  
  //println("<l>: loc(<count>), blank(<bl>), comment(<cl>), multi-comment(<ml>)");
  
  return count;
}

// calculate the cyclomatic complexity of the supplied method
public int countComplexity(str s) {
  int count = 1; 
  // count the number of branching statements
  for (/\b(?:if|for|while|case|catch)\b/ := s) {
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


// returns a list with blank lines and comment lines removed
// only returns a list when the clean list is > 6 LOC 
public list[str] cleanListing(list[str] dirtylist, int dsize) {
	list[str] cleanlist = [];
	for (a <- dirtylist) {
		// remove blank lines, comment lines (//) and multi-line comments from list (/*..*/) 
		if (!/^[\s]*[\/]{2}/ := a && !/^[\s]*$/m := a && !/\/\*[^*]*\*+(?:[^\/*][^*]*\*+)*\// := a) {
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
	int sizeSearchList = size(searchlist);
	int sizePattern = size(pattern);
	int loopSize = sizeSearchList-sizePattern+1;
	
		//println("loopSize:<loopSize>");
	for (i <- [0..(loopSize)]) {
		for (j <- [0..sizePattern]) {
			if ( !contains(searchlist[i+j], pattern[j]) ) {
				break;
			}
			hit += 1;
		}
		// if a match is found, skip patternsize and continue
		if (hit == sizePattern) {
			match += 1;
			i += sizePattern;
		}
		hit = 0;
	}
	return match;
}

// takes a pattern of blocksize from the code listing and 
// slides it in steps of blocksize over the code listing to
// find duplicate code
public int countDuplication(list[str] listing, int blocksize) {
	int dup_tot = 0;
	//println("Start duplication check...");
	map[str, int] duplicateLines = rangeX(distribution(listing) , {1});
	list[str] duplicateLinesValues = [k | k:_ <- duplicateLines];
	list[str] listingToCheck = [];
	for (i <- [0..size(listing)]) {
		if (indexOf(duplicateLinesValues, listing[i]) > -1) {
			listingToCheck += listing[i];
		}		
	}

	println("Size listingToCheck: <size(listingToCheck)>");
	int listingSize = size(listing);
	int loopSize = listingSize - blocksize + 1;
	
	for (i <- [0..(loopSize)], i % blocksize == 0) {
		list[str] pattern = [a | a <- listing[i..(i+blocksize)]];
		match = SearchForPattern(listingToCheck, pattern);
		if (match > 1) {
			//println("match:<match> at line i:<i>");
			dup_tot += (match - 1) * blocksize;
		}
		if (i % 100 == 0) println("   ..<(i*100)/listingSize>%");
	}

	return dup_tot;
}
