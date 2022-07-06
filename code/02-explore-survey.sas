%LET LIBRARY=KNHANES;
%LET DATA_STUDY_READY=&LIBRARY..HN16_17_18_STUDY_READY;
%LET STUDY_IN=age_in;

/* 위에 줄을 남겨 두고 아래부터 코딩 */

%MACRO CHISQ_COMPLEX(_analVar, __studyOutcome);
PROC SURVEYFREQ DATA=&DATA_STUDY_READY NOMCAR;
    STRATA kstrata;
    CLUSTER psu;
    WEIGHT wt_ex_pool;
    TABLES &STUDY_IN*&__studyOutcome*&_analVar / CHISQ;
%MEND;

%MACRO FREQ_COMPLEX(_studyOutcome);
    /* 1_연령대 */
    %CHISQ_COMPLEX(age_group, &_studyOutcome)
    RUN;

    /* 2_성별 */
    %CHISQ_COMPLEX(sex, &_studyOutcome)
    RUN;

    /* 3_거주지 */
    %CHISQ_COMPLEX(town, &_studyOutcome)
    RUN;

    /* 4_결혼 상태 */
    %CHISQ_COMPLEX(martial_status, &_studyOutcome)
    RUN;

    /* 5_교육 수준 */
    %CHISQ_COMPLEX(edu_1, &_studyOutcome)
    RUN;

    /* 6_가계 소득 */
    %CHISQ_COMPLEX(income, &_studyOutcome)
    RUN;

    /* 7_취업 형태 */
    %CHISQ_COMPLEX(occupation_type, &_studyOutcome)
    RUN;

    /* 8_규칙적인 운동 여부 */
    %CHISQ_COMPLEX(regular_workout, &_studyOutcome)
    RUN;

    /* 9_활동제한 여부 */
    %CHISQ_COMPLEX(activity_restriction, &_studyOutcome)
    RUN;

    /* 10_만성 질환 */
    %CHISQ_COMPLEX(chronic_disease, &_studyOutcome)
    RUN;

    /* 11_수면 시간 */
    %CHISQ_COMPLEX(sleep_length, &_studyOutcome)
    RUN;

    /* 12_현재 흡연자 여부 */
    %CHISQ_COMPLEX(C_sm1, &_studyOutcome)
    RUN;

    /* 13_음주 강도 */
    %CHISQ_COMPLEX(acl1, &_studyOutcome)
    RUN;

    /* 14_음주흡연 동시행위 */
    %CHISQ_COMPLEX(grp1, &_studyOutcome)
    RUN;
%MEND;

%FREQ_COMPLEX(PHQ)
RUN;

%FREQ_COMPLEX(COUNSELING)
RUN;
