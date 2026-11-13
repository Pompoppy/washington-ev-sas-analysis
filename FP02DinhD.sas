/* 
Programmed by: Dang Dinh 
Programmed on: 2026-11-10
Programmed to: Final Project Phase 2 For ST445(001)

Modified by: N/A 
Modified on: N/A
Modified to: N/A
*/

*Set librefs using only relative paths;
x "cd L:\st445";
libname P1Data "Results\FinalProjectPhase1" access = readonly; /*instructor's Phase 1 data sets*/

x "cd S:\ST445";
libname Final "."; /*project library for formats and the PDF*/

*set options;
options nodate fmtsearch = (Final);
ods noproctitle;

/*macro variables for the instructor's data sets*/
%let EVData = P1Data.FinalDugginsJEV;
%let VinData = P1Data.FinalDugginsJUniqueVinMask;
%let ModelData = P1Data.FinalDugginsJModels;
%let CrossData = P1Data.FinalDugginsJCafvCrossEV;

/*macro variables for titles and footnotes*/
%let IdStamp = Output created by by &SysUserID on &SysDate9 using &SysVLong;
%let TitleOpts = height = 14pt bold;
%let SubTitleOpts = height = 10pt bold;
%let FootOpts = j = left height = 8pt italic;

/*PROC1: formats for model year groups, range categories, CAFV labels, and color ramps*/
proc format library = Final;
    value YrGrp 
        low - 1999  = "Pre-2000"
        2000 - 2005 = "2000-2005"
        2006 - 2010 = "2006-2010"
        2011 - 2015 = "2011-2015"
        2016 - 2020 = "2015-2020"
        2021 - high = "2020-2025";
    value RangeCat 
        0           = "Not Yet Known"
        0 <-< 200   = "Poor"
        200 -< 250  = "Average"
        250 -< 300  = "Good"
        300 - high  = "Great"
        other       = "Invalid/Missing";
    value CAFVLbl 
        1 = "CAFV Eligible"
        2 = "Not CAFV Eligible"
        3 = "CAFV Eligibility Unknown";
    value BEVClr 
        0           = "cxFCAE91"
        0 <-< 200   = "cxF2F0F7"
        200 -< 250  = "cxCBC9E2"
        250 -< 300  = "cx9E9AC8"
        300 - high  = "cx6A51A3";
    value PHEVClr 
        0           = "cxFCAE91"
        0 <-< 25    = "cxF2F0F7"
        25 -< 50    = "cxCBC9E2"
        50 -< 75    = "cx9E9AC8"
        75 - high   = "cx6A51A3";
run;

*Only the PDF is produced, no matter which destinations are open;
ods _all_ close;
ods pdf file = "Final Dinh Washington State Electric Vehicle Study.pdf" style = sapphire dpi = 300 columns = 2;
ods graphics on / width = 6in;

footnote1 &FootOpts "&IdStamp";

*Output 1;
title1 &SubTitleOpts "Output 1";
title2 &TitleOpts "Listing of BEV Cars Not Known to be CAFV* Eligible";
title3 &SubTitleOpts "Partial Output -- Up to First 10 Records Shown per CAFV Status";
footnote2 &FootOpts "*Clean Alternative Fuel Vehicle";
proc print data = &EVData(obs = 10) noobs label;
    where EVTypeShort eq "BEV" and CAFVCode eq 2;
    var CAFVCode Make Model Erange;
    format CAFVCode CAFVLbl.;
    label CAFVCode = "CAFV Eligibility";
run;

*Output 1;
proc print data = &EVData(obs = 10) noobs label;
    where EVTypeShort eq "BEV" and CAFVCode eq 3;
    var CAFVCode Make Model Erange;
    format CAFVCode CAFVLbl.;
    label CAFVCode = "CAFV Eligibility";
run;

*Output 2;
title1 &SubTitleOpts "Output 2";
title2 &TitleOpts "Selected Summary Statistics of MSRP and Electric Range";
footnote2;
ods select Moments BasicMeasures MissingValues;
proc univariate data = &EVData;
    var BaseMSRP Erange;
run;

*Output 3;
title1 &SubTitleOpts "Output 3";
title2 &TitleOpts "Quantiles and Missing Data Summary of Base MSRP";
title3 &SubTitleOpts "Grouped by Model Year";
ods select Quantiles MissingValues;
proc univariate data = &EVData;
    class ModelYear;
    var BaseMSRP;
    format ModelYear YrGrp.;
run;

*Output 4;
title1 &SubTitleOpts "Output 4";
title2 &TitleOpts "90% Confidence Interval for Electric Range";
title3 &SubTitleOpts "Grouped by CAFV* Status and EV Type";
footnote2 &FootOpts "*Clean Alternative Fuel Vehicle";
proc means data = &VinData lclm mean uclm stderr n alpha = 0.10 maxdec = 3 nonobs;
    class CAFVCode EVTypeShort;
    var Erange;
run;

*Output 5;
title1 &SubTitleOpts "Output 5";
title2 &TitleOpts "Frequency Analysis of State";
title3 &SubTitleOpts "(Cumulative Statistics omitted)";
footnote2;
proc freq data = &EVData order = freq;
    tables StateCode / missing nocum; /*missing values shown in the table, not a footnote*/
run;

ods pdf columns = 1;

*Output 6;
title1 &SubTitleOpts "Output 6";
title2 &TitleOpts "Frequency Analysis of EV Type, Primary Utility*";
title3 &TitleOpts "and CAFV** by EV Type";
title4 &SubTitleOpts "(Cumulative Statistics omitted)";
footnote2 &FootOpts "*Defined as first electric utility listed in the data base for the vehicle location.";
footnote3 &FootOpts "**Clean Alternative Fuel Vehicle";
proc freq data = &EVData order = freq;
    tables EVTypeShort PrimaryUtil / nocum;
    tables CAFV*EVTypeShort / format = comma10.;
run;

*Output 7;
title1 &SubTitleOpts "Output 7";
title2 &TitleOpts "Frequency Analysis of Model Year by Electric Range";
title3 &SubTitleOpts "For BEV Cars Only";
footnote2 &FootOpts "Range categories: 0 = Not Yet Known; (0,200)=Poor; [200,250)=Average;[250,300)=Good;300+=Great;Other=Invalid/Missing";
proc freq data = &EVData;
    where EVTypeShort eq "BEV";
    tables ModelYear*Erange / format = comma10.;
    format ModelYear YrGrp. Erange RangeCat.;
run;

*Output 8;
title1 &SubTitleOpts "Output 8";
title2 &TitleOpts "Frequency Analysis of Model Year by Electric Range";
title3 &SubTitleOpts "Only for BEV Cars with Reported (>0) Ranges";
proc freq data = &EVData;
    where EVTypeShort eq "BEV" and Erange gt 0;
    tables ModelYear*Erange / format = comma10.;
    format ModelYear YrGrp. Erange RangeCat.;
run;

*Outputs 9 and 10 share one page;
ods pdf startpage = never;

*Output 9;
title1 &SubTitleOpts "Output 9";
title2 &TitleOpts "Frequency of EV Type for Each CAFV Elibility Category";
footnote2;
proc sgplot data = &CrossData;
    where _TYPE_ eq "11"; /*only the cell percentages, not the margins*/
    styleattrs datacolors = (cxE7298A cx66A61E); /*ColorBrewer Dark2*/
    vbar CAFVCode / response = RowPercent group = EVTypeShort barwidth = 0.5 nooutline;
    xaxis label = "CAFV Eligibility" values = (1 2 3) valuesdisplay = ("Yes" "No" "Unknown");
    yaxis label = "% of CAFV Category" values = (0 to 100 by 10);
    keylegend / title = "EV Type" location = inside position = topright across = 1;
run;

*Output 10;
title1 &SubTitleOpts "Output 10";
title2 &TitleOpts "Frequency of CAFV Elibility Category for Each EV Type";
proc sgplot data = &CrossData;
    where _TYPE_ eq "11";
    styleattrs datacolors = (cx1B9E77 cxD95F02 cx7570B3); /*ColorBrewer Dark2*/
    hbar EVTypeShort / response = ColPercent group = CAFVCode groupdisplay = cluster nooutline
                       datalabel datalabelattrs = (size = 10pt color = gray);
    xaxis label = "% of EV Type" values = (0 to 100 by 10);
    yaxis label = "EV Type";
    keylegend / title = "CAFV" location = inside position = topright across = 1;
    format CAFVCode CAFVLbl.;
run;

ods pdf startpage = yes;

*Output 11;
title1 &SubTitleOpts "Output 11";
title2 &TitleOpts "Comparative Boxplots for Electric Range";
title3 &SubTitleOpts "Excluding Missing or Non-US State Postal Codes";
proc sgplot data = &EVData;
    where StateCode not in (" " "AP" "BC"); /*matches the states shown in the client mock-up*/
    vbox Erange / group = StateCode;
    keylegend / title = "State" position = right down = 20;
run;

ods pdf columns = 2;

*Output 12;
title1 &SubTitleOpts "Output 12";
title2 &TitleOpts "Frequency of Masked VIN Under 70/30 Plan";
title3 &SubTitleOpts "Showing Only: Make = JEEP";
proc freq data = &VinData order = freq;
    where Make eq "JEEP";
    tables MaskVin / nocum;
run;

ods pdf columns = 1;

*Output 13;
title1 &SubTitleOpts "Output 13";
title2 &TitleOpts "Listing of EV Makes and Models";
footnote2 &FootOpts "Wow. This is just an awful table. Please don't ever make something like this ever again. Seriously. This is bad.";
proc report data = &ModelData;
    column ("Vehicle Make" Make) ("Models in Database" Model1-Model14);
    define Make / id " "; /*row header repeats on every page*/
    define Model1-Model14 / display " "; /*one DEFINE for all model columns*/
run;

*Output 14;
title1 &SubTitleOpts "Output 14";
title2 &TitleOpts "Analyis of Electric Range and Base MSRP";
title3 &SubTitleOpts "Grouped by Model Year, EV Type*, and CAFV Eligibility";
footnote2 &FootOpts "*Due to substantial differences between range for PHEV and BEV, pooled statistics should not be used for inferences";
proc report data = &EVData;
    column ModelYear EVTypeShort CAFVCode 
           ("Electric Range" Erange = ErMean Erange = ErStd Erange = ErN)
           ("Base MSRP" BaseMSRP = MsMean BaseMSRP = MsStd BaseMSRP = MsN);
    define ModelYear / group order = internal format = YrGrp. "Vehicle Model Year";
    define EVTypeShort / group "EV Type";
    define CAFVCode / group format = CAFVLbl. "CAFV";
    define ErMean / mean format = 6.1 "Mean";
    define ErStd / std format = 6.2 "Std. Dev.";
    define ErN / n format = comma6. "Count";
    define MsMean / mean format = dollar10. "Mean";
    define MsStd / std format = dollar10. "Std. Dev.";
    define MsN / n format = comma6. "Count";
    break after ModelYear / summarize;
run;

*Output 15;
title1 &SubTitleOpts "Output 15";
title2 &TitleOpts "Analyis of Electric Range and Base MSRP";
title3 &SubTitleOpts "Grouped by Model Year, EV Type*, and CAFV Eligibility";
footnote3 &FootOpts "Alternative Display: EV Type displays on all non-summary rows";
proc report data = &EVData;
    column ModelYear EVTypeShort CAFVCode 
           ("Electric Range" Erange = ErMean Erange = ErStd Erange = ErN)
           ("Base MSRP" BaseMSRP = MsMean BaseMSRP = MsStd BaseMSRP = MsN);
    define ModelYear / group order = internal format = YrGrp. "Vehicle Model Year";
    define EVTypeShort / group "EV Type";
    define CAFVCode / group format = CAFVLbl. "CAFV";
    define ErMean / mean format = 6.1 "Mean";
    define ErStd / std format = 6.2 "Std. Dev.";
    define ErN / n format = comma6. "Count";
    define MsMean / mean format = dollar10. "Mean";
    define MsStd / std format = dollar10. "Std. Dev.";
    define MsN / n format = comma6. "Count";
    break after ModelYear / summarize;
    compute before EVTypeShort; /*hold the EV type at the start of each EV type group*/
        length EVHold $ 4;
        EVHold = EVTypeShort;
    endcomp;
    compute EVTypeShort; /*carry the EV type down on every detail row*/
        if missing(_break_) then EVTypeShort = EVHold;
    endcomp;
run;

*Output 16;
title1 &SubTitleOpts "Output 16";
title2 &TitleOpts "Color-Coded Analyis of Electric Range and Base MSRP";
title3 &SubTitleOpts "Grouped by Model Year, EV Type*, and CAFV Eligibility";
footnote3 &FootOpts "*Despite PHEV and BEV range differences, all color-coding uses BEV cutoffs.";
footnote4 &FootOpts "Alternative Display: EV Type displays on all non-summary rows";
proc report data = &EVData;
    column ModelYear EVTypeShort CAFVCode 
           ("Electric Range" Erange = ErMean Erange = ErStd Erange = ErN)
           ("Base MSRP" BaseMSRP = MsMean BaseMSRP = MsStd BaseMSRP = MsN);
    define ModelYear / group order = internal format = YrGrp. "Vehicle Model Year";
    define EVTypeShort / group "EV Type";
    define CAFVCode / group format = CAFVLbl. "CAFV";
    define ErMean / mean format = 6.1 "Mean" style(column) = [backgroundcolor = BEVClr.]; /*data-driven colors*/
    define ErStd / std format = 6.2 "Std. Dev.";
    define ErN / n format = comma6. "Count";
    define MsMean / mean format = dollar10. "Mean";
    define MsStd / std format = dollar10. "Std. Dev.";
    define MsN / n format = comma6. "Count";
    break after ModelYear / summarize style = [backgroundcolor = cxCCCCCC];
    compute before EVTypeShort;
        length EVHold $ 4;
        EVHold = EVTypeShort;
    endcomp;
    compute EVTypeShort;
        if missing(_break_) then EVTypeShort = EVHold;
    endcomp;
    compute after / style = [backgroundcolor = black color = white just = right]; /*table footer describing the colors*/
        line "Electric range-based coloring:<200,  200-250, 250-300, >300";
    endcomp;
run;

*Output 17;
title1 &SubTitleOpts "Output 17";
title2 &TitleOpts "Color-Coded Analyis of Electric Range and Base MSRP";
title3 &SubTitleOpts "Grouped by Model Year, EV Type*, and CAFV Eligibility";
footnote3 &FootOpts "*BEV and PHEV rows use their respective cutoffs. Summary rows use BEV cutoffs.";
footnote4 &FootOpts "Alternative Display: EV Type displays on all non-summary rows";
proc report data = &EVData;
    column ModelYear EVTypeShort CAFVCode 
           ("Electric Range" Erange = ErMean Erange = ErStd Erange = ErN)
           ("Base MSRP" BaseMSRP = MsMean BaseMSRP = MsStd BaseMSRP = MsN);
    define ModelYear / group order = internal format = YrGrp. "Vehicle Model Year";
    define EVTypeShort / group "EV Type";
    define CAFVCode / group format = CAFVLbl. "CAFV";
    define ErMean / mean format = 6.1 "Mean" style(column) = [backgroundcolor = BEVClr.];
    define ErStd / std format = 6.2 "Std. Dev.";
    define ErN / n format = comma6. "Count";
    define MsMean / mean format = dollar10. "Mean";
    define MsStd / std format = dollar10. "Std. Dev.";
    define MsN / n format = comma6. "Count";
    break after ModelYear / summarize style = [backgroundcolor = cxCCCCCC];
    compute before EVTypeShort;
        length EVHold $ 4;
        EVHold = EVTypeShort;
    endcomp;
    compute EVTypeShort;
        if missing(_break_) then EVTypeShort = EVHold;
    endcomp;
    compute ErMean; /*PHEV detail rows switch to the PHEV cutoffs, same colors*/
        if EVHold eq "PHEV" and missing(_break_) then 
            call define(_col_, "style", cats("style=[backgroundcolor=", put(ErMean, PHEVClr.), "]"));
    endcomp;
    compute after / style = [backgroundcolor = black color = white just = right];
        line "BEV range-based coloring:<200, 200-250, 250-300, >300";
        line "PHEV range-based coloring:<25, 25-50, 50-75, >75";
    endcomp;
run;

title;
footnote;
ods pdf close;

quit;
