/* 
Programmed by: Dang Dinh 
Programmed on: 2026-11-09
Programmed to: Final Project Phase 1 For ST445(001)

Modified by: N/A 
Modified on: N/A
Modified to: N/A
*/

*Set filerefs and librefs using only relative paths;
x "cd L:\st445";
filename RawData "Data\WashingtonState\RawData"; /*client raw files (yes, no, unk)*/
libname ClientFm "Data\WashingtonState\FormatCatalogs"; /*client formats and informats for make and model*/
libname LookUp access "Data\WashingtonState\StructuredData\LookUp.accdb"; /*client Access lookup tables*/

x "cd S:\ST445";
libname Final "."; /*project library for every data set and format I save*/

*set options;
options fmtsearch = (Final ClientFm); /*look for my formats first, then the client formats*/

*No printed output in Phase 1, only data sets;
ods _all_ close;

/*macro variables to cut down on repeated code*/
%let GrpSize = 250; /*number of values in each variable group of the unk file*/

%let RawAttrs = Vin             length = $10
                Zip             length = $5
                LegDist         length = $2
                DOLID           length = $9
                CensusTract2020 length = $11
                ElecUtil        length = $200
                Location        length = $33;
/*same lengths for all three raw files so they stack cleanly, labels and formats are set in the last DATA step*/

/*PROC1: create formats for wordy months, CAFV descriptions, and non-US state names*/
proc format library = Final;
    value $MonNum 
        "January"   = "1"
        "February"  = "2"
        "March"     = "3"
        "April"     = "4"
        "May"       = "5"
        "June"      = "6"
        "July"      = "7"
        "August"    = "8"
        "September" = "9"
        "October"   = "10"
        "November"  = "11"
        "December"  = "12";
    value CAFVDesc 
        1 = "Clean Alternative Fuel Vehicle Eligible"
        2 = "Not eligible due to low battery range"
        3 = "Eligibility unknown as battery range has not been researched";
    value $NonUS 
        "AE" = "Armed Forces Europe"
        "AP" = "Armed Forces Pacific"
        "BC" = "British Columbia";
run;

/* DATA1: read the yes file (comma then tab delimited, one record per line) */
data YesCAFV;
    attrib &RawAttrs;
    infile RawData("EV-CAFV(yes).txt") dlm = "2C09"x dsd firstobs = 6 truncover; /*comma or tab as delimiter, dsd for quoted utilities with commas*/
    input Vin Zip LegDist DOLID CensusTract2020 RegDate :yymmdd10. ElecUtil Location;
run;

/* DATA2: read the no file (fixed columns, one record across three lines) */
data NoCAFV;
    attrib &RawAttrs;
    infile RawData("EV-CAFV(no).txt") firstobs = 8 truncover; /*truncover so short lines do not jump to next record*/
    input Vin $ 1-10 
          Zip $ 11-15 
          LegDist $ 16-17 
          DOLID $ 18-26 
          CensusTract2020 $ 28-38 
          RegDate 39-43 /*already stored as a SAS date number*/
        / ElecUtil $ 1-112 /*line 2 of the record*/
        / Location $ 1-33; /*line 3 of the record*/
run;

/* DATA3: read the unk file, one VIN per line with 7 groups of &GrpSize values, output one row per non-empty group slot */
data UnkCAFV;
    attrib &RawAttrs;
    infile RawData("EV-CAFV(unk).txt") dlm = ";" dsd firstobs = 12 truncover; /*semicolon delimited, dsd so empty slots stay missing*/
    array ZipG[&GrpSize] $ 5;
    array LDG[&GrpSize] $ 2;
    array DOLIDG[&GrpSize] $ 9;
    array TractG[&GrpSize] $ 11;
    array DateG[&GrpSize] $ 18;
    array UtilG[&GrpSize] $ 112;
    array LocG[&GrpSize] $ 33;
    input Vin ZipG1-ZipG&GrpSize LDG1-LDG&GrpSize DOLIDG1-DOLIDG&GrpSize TractG1-TractG&GrpSize
          DateG1-DateG&GrpSize UtilG1-UtilG&GrpSize LocG1-LocG&GrpSize; /*read each group in the file order*/
    do i = 1 to &GrpSize;
        if not missing(ZipG[i]) or not missing(LDG[i]) or not missing(DOLIDG[i]) or not missing(TractG[i])
           or not missing(DateG[i]) or not missing(UtilG[i]) or not missing(LocG[i]) then do; /*skip slots missing all 7 core variables*/
            Zip = ZipG[i];
            LegDist = LDG[i];
            DOLID = DOLIDG[i];
            CensusTract2020 = TractG[i];
            RegDate = mdy(input(put(propcase(scan(DateG[i], 3, " ,")), $MonNum.), 2.), /*month name to number*/
                          input(scan(DateG[i], 2, " ,"), 2.), /*day of month*/
                          input(scan(DateG[i], 1, " ,"), 4.)); /*year*/
            ElecUtil = UtilG[i];
            Location = LocG[i];
            output;
        end;
    end;
    drop i ZipG1-ZipG&GrpSize LDG1-LDG&GrpSize DOLIDG1-DOLIDG&GrpSize TractG1-TractG&GrpSize
         DateG1-DateG&GrpSize UtilG1-UtilG&GrpSize LocG1-LocG&GrpSize; /*group variables are no longer needed*/
run;

/* DATA4: stack all CAFV records and derive variables that depend on the source file */
data AllCAFV;
    set YesCAFV(in = inYes) 
        NoCAFV(in = inNo) 
        UnkCAFV(in = inUnk);
    ZipN = input(Zip, 5.); /*numeric zip for the Sashelp.ZipCode lookup*/
    CAFVCode = inYes + 2*inNo + 3*inUnk; /*1 = yes, 2 = no, 3 = unk without conditional logic*/
    CAFV = put(CAFVCode, CAFVDesc.);
run;

/*PROC2: sort by VIN to match the Demographics table*/
proc sort data = AllCAFV;
    by Vin;
run;

/* DATA5: add the vehicle information from Demographics, only for VINs in this study */
data CAFVDemo;
    merge AllCAFV(in = inCAFV) 
          LookUp.Demographics;
    by Vin;
    if inCAFV; /*drop Demographics VINs that are not in our data*/
run;

/*PROC3: sort by numeric zip to match Sashelp.ZipCode*/
proc sort data = CAFVDemo;
    by ZipN;
run;

/* DATA6: add city, state, and county information from Sashelp.ZipCode for domestic records */
data CAFVZip;
    merge CAFVDemo(in = inEV) 
          Sashelp.ZipCode(keep = Zip City State StateCode StateName County CountyNm 
                          rename = (Zip = ZipN City = CityName State = StateFips 
                                    County = CountyFips CountyNm = CountyName));
    by ZipN;
    if inEV; /*only keep zip codes that appear in our data*/
run;

/*PROC4: sort by DOLID to match the Non-Domestic Registrations table*/
proc sort data = CAFVZip;
    by DOLID;
run;

/* DATA7: add non-US states, set final attributes from the client metadata, and derive the client variables */
data Final.FinalDinhDEV;
    attrib Vin             length = $10   format = $10.       informat = $10.  label = "Vehicle Identification Number"
           MaskVin         length = $10                                         label = "Partially Masked VIN"
           Zip             length = $5                                          label = "Vehicle Registration Zip Code"
           ZipN                           format = z5.                          label = "Vehicle Registration Zip Code"
           CityName        length = $35                                         label = "City Name"
           StateFips                                                            label = "State FIPS"
           StateCode       length = $2                                          label = "State Postal Code"
           StateName       length = $25                                         label = "State Name"
           CountyFips                                                           label = "County FIPS"
           CountyName      length = $25                                         label = "County Name"
           LegDist         length = $2                                          label = "Vehicle Registration Legislative District"
           DOLID           length = $9    format = $9.        informat = $9.   label = "WA Department of Licensing ID"
           CensusTract2020 length = $11                                         label = "Vehicle Registration US Census Tract"
           RegDate                        format = yymmdd10.                    label = "Last Registration Date"
           ModelYear                                                            label = "Vehicle Model Year"
           EVType          length = $50   format = $50.       informat = $50.  label = "EV Type (long)"
           EVTypeShort     length = $4                                          label = "EV Type (short)"
           Erange                                                               label = "Electric Range"
           BaseMSRP                                                             label = "Reported Base MSRP"
           Make            length = $20                                         label = "Vehicle Make"
           Model           length = $25                                         label = "Vehicle Model"
           CAFV            length = $60                                         label = "Clean Alternative Fuel Vehicle Eligible Description"
           CAFVCode                                                             label = "Clean Alternative Fuel Vehicle Eligible (1=Y,2=N,3=U)"
           ElecUtil        length = $200                                        label = "Electric Utilities Servicing Vehicle Registration Address"
           PrimaryUtil     length = $200                                        label = "Primary Electric Utility at Vehicle Location"
           Latitude                       format = 13.8                         label = "Vehicle Registration Latitude (decimal)"
           Longitude                      format = 13.8                         label = "Vehicle Registration Longitude (decimal)";
    /*attributes and variable order taken from the client metadata*/
    merge CAFVZip(in = inEV) 
          LookUp.'Non-Domestic Registrations'n;
    by DOLID;
    if inEV; /*only keep DOLIDs in our data*/

    /*non-US records get state info from the lookup table instead of Sashelp.ZipCode*/
    if not missing(st) then do;
        StateCode = st;
        StateName = put(st, $NonUS.);
        ElecUtil = "NON WASHINGTON STATE ELECTRIC UTILITY";
    end;

    /*location is POINT (longitude latitude)*/
    Longitude = input(scan(Location, 2, " ()"), best32.);
    Latitude = input(scan(Location, 3, " ()"), best32.);

    PrimaryUtil = scan(ElecUtil, 1, "|"); /*first utility in the pipe-delimited list*/
    MaskVin = cats("*******", substr(Vin, 8)); /*replace first 7 characters with asterisks*/
    EVTypeShort = scan(EVType, 2, "()"); /*BEV or PHEV is the 2nd word when splitting on parentheses*/
    Make = input(MakeCat, $evMake.); /*client informat turns make code into make name*/
    Model = input(ModelCat, $evModel.); /*client informat turns model code into model name*/

    /*clean up poorly reported MSRP with special missing values*/
    if missing(BaseMSRP) then BaseMSRP = .M;
    else if BaseMSRP lt 0 then BaseMSRP = .I;
    else if BaseMSRP eq 0 then BaseMSRP = .Z;

    drop st Location MakeCat ModelCat; /*helper variables not in the client metadata*/
run;

*Disconnect from the Access file so others can use it;
libname LookUp clear;

/*PROC5: keep one record per VIN to study the masking strategy*/
proc sort data = Final.FinalDinhDEV out = Final.FinalDinhDUniqueVinMask nodupkey;
    by Vin;
run;

/*PROC6: save all percentages from the CAFV by EV type two-way table*/
ods output CrossTabFreqs = Final.FinalDinhDCafvCrossEV(keep = CAFVCode EVTypeShort _TYPE_ Percent RowPercent ColPercent);
proc freq data = Final.FinalDinhDEV;
    tables CAFVCode*EVTypeShort;
run;

/*PROC7: one record for each Make and Model combination*/
proc sort data = Final.FinalDinhDUniqueVinMask(keep = Make Model) out = MakeModel nodupkey;
    by Make Model;
run;

/*PROC8: one record per Make with a column for every Model*/
proc transpose data = MakeModel out = Final.FinalDinhDModels(drop = _name_ _label_) prefix = Model;
    by Make;
    var Model;
run;

*Reopen the LISTING destination;
ods listing;

quit;
