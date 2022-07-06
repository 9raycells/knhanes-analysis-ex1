%LET LIBRARY=KNHANES;
%LET DATA_STUDY_READY=&LIBRARY..HN16_17_18_STUDY_READY;
%LET STUDY_IN=bp7_in;   /* phq_in, eq5d_in or bp7_in */
%LET STUDY_OUTCOME=BP7_1; /* phq, EQ5D, BP7_1 */

/* 위에 %LET 문장을 남겨 두고 아래부터 코딩 */

DATA &DATA_STUDY_READY;
    SET &DATA_STUDY_READY;
    IF EQ5D_IN = 1 THEN DO;
        IF LQ_5EQL=1 THEN eq5d = 0;
        ELSE IF LQ_5EQL IN (2, 3) THEN eq5d = 1;
    END;
RUN;

DATA &DATA_STUDY_READY;
    SET &DATA_STUDY_READY;
    IF BP7_IN = 1 THEN DO;
        IF BP7 = 1 THEN BP7_1 = 1;
        ELSE IF BP7=2 THEN BP7_1 =0;
    END;
RUN;

PROC SURVEYLOGISTIC DATA=&DATA_STUDY_READY NOMCAR;
    STRATA  kstrata;
    CLUSTER psu;
    WEIGHT  wt_ex_pool;
    DOMAIN  &STUDY_IN;
    CLASS   age_group(REF='2') sex(REF='1') /*town(REF='1')*/ /*martial_status(REF='1')*/ /*edu(REF='1')*/
            occupation_type(REF='3') /*ho_incm(REF='1')*/ /*chronic_disease(REF='0')*/
            regular_workout(REF='1') LQ4_00(REF='2') sleep_length(REF='2')
            C_sm1(REF='0') acl1(REF='1')
            / PARAM=ref;
    MODEL   &STUDY_OUTCOME(EVENT='1') = age_group sex /*town*/ /*martial_status*/ /*edu*/
                                        occupation_type /*ho_incm*/ /*chronic_disease*/
                                        regular_workout LQ4_00 sleep_length C_sm1 acl1
            / VADJUST=none DF=INFINITY;
RUN;

PROC SURVEYLOGISTIC DATA=&DATA_STUDY_READY NOMCAR;
    STRATA  kstrata;
    CLUSTER psu;
    WEIGHT  wt_ex_pool;
    DOMAIN  &STUDY_IN;
    CLASS   age_group(REF='2') sex(REF='1') /*town(REF='1')*/ /*martial_status(REF='1')*/ /*edu(REF='1')*/
            occupation_type(REF='3') /*ho_incm(REF='1')*/ /*chronic_disease(REF='0')*/
            regular_workout(REF='1') LQ4_00(REF='2') sleep_length(REF='2') grp1(REF='group1')
            / PARAM=ref;

    MODEL   &STUDY_OUTCOME(EVENT='1') = age_group sex /*town*/ /*martial_status*/ /*edu*/
                                        occupation_type /*ho_incm*/ /*chronic_disease*/
                                        regular_workout LQ4_00 sleep_length grp1
            / VADJUST=none DF=INFINITY;
RUN;

