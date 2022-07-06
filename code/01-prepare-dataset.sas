/*
 * # 라이브러, 데이터셑 이름 지정
 *
 * - LIBRARY              - 라이브러리 이름
 * - DATA_RAW             - 조사연구 원본 데이터셑
 * - DATA_KEEP            - 원본 본데이터로부터 필요한 변수만 KEEP한 데이터셑
 * - DATA_STUDY_SELECTION - KEEP 데이터셑에서 연구대상을 마킹한 데이터셑
 * - DATA_STUDY_READY     - STUDY_SELECTION 데이터셑에서 사용변수를 추가한 데이터셑
 */
%LET LIBRARY=KNHANES;
%LET DATA_RAW=&LIBRARY..HN16_17_18_ALL;
%LET DATA_KEEP=&LIBRARY..HN16_17_18_KEEP;
%LET DATA_STUDY_SELECTION=&LIBRARY..HN16_17_18_STUDY_SELECTION;
%LET DATA_STUDY_READY=&LIBRARY..HN16_17_18_STUDY_READY;

%LET KNHANES=7;

/*
 * # 데이터 추출 절차
 *
 * 1. DO_DATA_RAW
 * 2. DO_DATA_KEEP
 * 3. DO_STUDY_SELECTION
 * 4. DO_STUDY_READY
 *
 * - 목적 -필요한 추출 단계만 선택적으로
 *   1. KNHANES 데이터 인코딩(EUC-KR)과 SAS OnDemand 지원 인코딩(UTF-8)이 다르다.
 *      KEEP으로 생성된 데이터셑에는 인코딩 문제가 발생하는 한글 데이터가 없으므로,
 *      PC버전 SAS로 KEEP한 데이터셑를 공유하여 사용한다.
 *   2. KEEP 데이터셑 뿐 아니라 STUDY_SELECTION, STUDY_READY 데이터 등도 공유한다.
 */

/*
 * DATA_RAW 생성
 */
%MACRO DO_DATA_RAW;
DATA &DATA_RAW;
    SET &LIBRARY..HN16_ALL &LIBRARY..HN17_ALL &LIBRARY..HN18_ALL;
    IF year = 2016 THEN wt_ex_pool=wt_itvex*(192/576);
    IF year = 2017 THEN wt_ex_pool=wt_itvex*(192/576);
    IF year = 2018 THEN wt_ex_pool=wt_itvex*(192/576);
RUN;
%MEND;

%MACRO DO_DATA_KEEP;
DATA &DATA_KEEP;
    SET &DATA_RAW;

    KEEP ID town_t psu sex age ho_incm edu wt_hs wt_itvex kstrata occp
         /* 결혼상태 */
         marri_1 marri_2
         /* 취업형태 */
         EC1_1 EC_occp EC_stt_1 EC_stt_2 EC_wht_0
         /* 만성질환 */
         DI1_pr DI2_pr DI3_pr DI5_pr DI6_pr DM2_pr DM3_pr DM4_pr /*DM8_pr*/
         DJ2_pr DJ4_pr DJ6_pr DJ8_pr DF2_pr DN1_pr DL1_pr DE1_pr DE2_pr
         DH4_pr DC1_pr DC2_pr DC3_pr DC4_pr DC5_pr DC6_pr DC7_pr DC11_pr
         DC12_pr DK8_pr DK9_pr DK4_pr HE_PFTtr BP17_dg
         /* 중강도, 고강도 신체활동 */
         BE3_71 BE3_72 BE3_81 BE3_82
         /* 활동제한 및 삶의 질 */
         LQ4_00 LQ_5EQL
         /* 수면시간 (제7기 2016-2018) */
         Total_slp_wk Total_slp_wd
         /* 수면시간 (그 외)*/
         BP16_1 BP16_2
         /* 흡연 */
         BS1_1 BS3_1 BS3_2 BS3_3 BS6_2 BS6_2_1 BS6_2_2 BS6_3
         /* 음주 */
         BD1 BD1_11 BD2_1 BD2_14 BD2_31 BD2_32
         /* PHQ-9 */
         BP_PHQ_1 BP_PHQ_2 BP_PHQ_3 BP_PHQ_4 BP_PHQ_5 BP_PHQ_6 BP_PHQ_7 BP_PHQ_8 BP_PHQ_9 mh_PHQ_S
         /* 기타 정신건강 - 스트레스, 자살, 우울감, 상담경험 */
         BP1    BP6_10 BP6_2 BP6_31    BP5    BP7
         /* 우울증 */
         DF2_dg
         /* 통합 가중치(wt_itvex->wt_ex_pool) */
         wt_ex_pool;
RUN;
%MEND;

/*
 * DATA_STUDY_SELECTION 생성
 */
%MACRO DO_STUDY_SELECTION;
DATA &DATA_STUDY_SELECTION;
    SET &DATA_KEEP;

    /* 연구 대상 - 나이 19~59 */
    IF age >= 20 AND age <= 59 THEN age_in = 1;
                               ELSE age_in = 0;

    /* 연구 대상 - 흡연 응답이 있는 자 */
    IF BS3_1 IN (1, 2, 3) OR BS1_1 = 3 THEN smoke_in = 1;
                                        ELSE smoke_in = 0;

    /* 연구 대상 - 음주 응답이 있는 자 */
    IF (BD1_11 IN (1:6) AND BD2_1 IN (1:8)) OR
       (sex = 1 AND BD2_31 IN (1:5)) OR
       (sex = 2 AND (BD2_31 IN (1:5) OR BD2_32 IN (1:5))) THEN alcohol_in = 1;
                                                          ELSE alcohol_in = 0;

    IF edu IN (1, 2, 3, 4) THEN edu_in = 1;
                           ELSE edu_in = 0;

    /* 연구 대상 - 나이, 성별, 거주지역 응답이 있는 자 */
    ** 나이, 성별, 거주지역은 기본정보로서 모두 있다고 가정;

    /* 연구 대상 - 결혼상태 응답이 있는 자 */
    IF marri_1 IN (1, 2) AND marri_2 ^= 8 THEN
        martial_status_in = 1;
    ELSE
        martial_status_in = 0;

    /* 연구 대상 - 취업형태 응답이 있는 자 */
    IF EC1_1 = 2 OR
       (EC1_1 = 1 AND EC_stt_1 IN (1, 2, 3) AND EC_wht_0 IN (1, 2, 8))
    THEN occupation_type_in = 1;
    ELSE occupation_type_in = 0;

    /* 연구 대상 - 소득수준 응답이 있는 자 */
    IF ho_incm IN (1:4) THEN income_in = 1;
                        ELSE income_in = 0;

    /* 연구 대상 - 만성질환 응답이 있는 자 */
    IF DI1_pr IN (0, 1) OR DI2_pr IN (0, 1) OR DI3_pr IN (0, 1) OR DI5_pr IN (0, 1) OR
       DI6_pr IN (0, 1) OR DM2_pr IN (0, 1) OR DM3_pr IN (0, 1) OR DM4_pr IN (0, 1) OR
       /*DM8_pr IN (0, 1) OR*/ DJ2_pr IN (0, 1) OR DJ4_pr IN (0, 1) OR DJ6_pr IN (0, 1) OR
       DJ8_pr IN (0, 1) OR /*DF2_pr IN (0, 1) OR*/ DN1_pr IN (0, 1) OR DL1_pr IN (0, 1) OR
       DE1_pr IN (0, 1) OR DE2_pr IN (0, 1) OR DH4_pr IN (0, 1) OR DC1_pr IN (0, 1) OR
       DC2_pr IN (0, 1) OR DC3_pr IN (0, 1) OR DC4_pr IN (0, 1) OR DC5_pr IN (0, 1) OR
       DC6_pr IN (0, 1) OR DC7_pr IN (0, 1) OR DC11_pr IN (0, 1) OR DC12_pr IN (0, 1) OR
       DK8_pr IN (0, 1) OR DK9_pr IN (0, 1) OR DK4_pr IN (0, 1) OR
       HE_PFTtr IN (1, 2, 3) OR BP17_dg IN (0, 1) THEN
        chronic_disease_in = 1;
    ELSE
        chronic_disease_in = 0;

    /* 연구 대상 - 활동제한 여부 응답이 있는 자 */
    IF LQ4_00 IN (1, 2) THEN activity_in = 1;
                        ELSE activity_in = 0;

    /* 연구 대상 - 중강도~고강도 신체활동 응답이 있는 자 */
    IF (BE3_71 IN (1, 2) AND BE3_72 IN (0:8)) or
       (BE3_81 IN (1, 2) AND BE3_82 IN (0:8)) THEN workout_in = 1;
                                              ELSE workout_in = 0;

    /* 연구 대상 - 수면시간 응답이 있는 자 */
%IF &KNHANES=7 %THEN %DO;
    /* 제7기 2016-2018 */
    IF 0 <= Total_slp_wk < 8888 OR 0 <= Total_slp_wd < 8888 THEN
        sleep_length_in = 1;
    ELSE
        sleep_length_in = 0;
%END;
%ELSE %DO;
    /* 그 외 */
    IF 0 <= BP16_1 <= 24 or 0 <= BP16_2 <= 24 THEN
        sleep_length_in = 1;
    ELSE
        sleep_length_in = 0;
%END;

    IF age_in = 1 & /*martial_status_in = 1 &*/ /*edu_in = 1 &*/ occupation_type_in = 1 &
       /*income_in = 1 &*/ /*chronic_disease_in = 1 &*/ workout_in = 1 & activity_in = 1 &
       sleep_length_in = 1 & smoke_in = 1 & alcohol_in = 1
    THEN
        study_in = 1;
    ELSE
        study_in = 0;

    /* 연구 구대상 - 결과변수로서 PHQ-9 점수 기록이 있는 자 */
    IF study_in = 1 AND mh_PHQ_S IN (0:27) THEN
        phq_in = 1;
    ELSE
        phq_in = 0;

    /* 연구 구대상 - 결과변수로서 EuroQoL: 불안/우울 응답이 있는 자 */
    IF study_in = 1 AND LQ_5EQL IN (1,2,3) THEN
        eq5d_in = 1;
    ELSE
        eq5d_in = 0;

    /* 연구 구대상 - 결과변수로서 1년간 정신 문제 상담 경험 응답이 있는 자 */
    IF study_in = 1 AND BP7 IN (1,2) THEN
        bp7_in = 1;
    ELSE
        bp7_in = 0;

RUN;

PROC FREQ DATA=&DATA_STUDY_SELECTION;
    TABLE age_in smoke_in alcohol_in martial_status_in occupation_type_in
          chronic_disease_in activity_in workout_in sleep_length_in
          study_in phq_in eq5d_in bp7_in;
RUN;
%MEND;

/*
 * DATA_STUDY_READY 생성
 */
%MACRO DO_STUDY_READY;
DATA &DATA_STUDY_READY;
    SET &DATA_STUDY_SELECTION;

    /* 흡연자 그룹(C_sm1: 비현재흡연자=0, 현재흡연자=1) */
    IF (BS1_1=3 OR BS3_1=3)      THEN C_sm1=0;
    ELSE IF (BS3_1=1 OR BS3_1=2) THEN C_sm1=1;

    /* 음주자 그룹(acl1: 정상음주군&비음주군=1, 고위험음주군=2) */
    IF sex=1 AND (
       (BD1_11 IN (5, 6) AND BD2_1 IN (4, 5)) OR
        BD2_31 IN (4, 5)) THEN acl1=2;
    ELSE IF sex=2 AND (
            (BD1_11 IN (5, 6) AND BD2_1 IN (3, 4, 5)) OR
             BD2_31 IN (4, 5) OR BD2_32 IN (4, 5)) THEN acl1=2;
    ELSE acl1=1;

    /* 그룹화(grp1: 흡연X음주X=group1, 흡연X고음주=group2, 흡연O음주X=group3, 흡연O고음주=group4) */;
    IF C_sm1=0 AND acl1=1      THEN grp1='group1';
    ELSE IF C_sm1=0 AND acl1=2 THEN grp1='group2';
    ELSE IF C_sm1=1 AND acl1=1 THEN grp1='group3';
    ELSE IF C_sm1=1 AND acl1=2 THEN grp1='group4';

    /* 만성질환(chronic_disease: 없음(0), 있음(1)) */
    IF DI1_pr=1 OR DI2_pr=1 OR DI3_pr=1 OR DI5_pr=1 OR DI6_pr=1 OR
       DM2_pr=1 OR DM3_pr=1 OR DM4_pr=1 OR /*(제8기) DM8_pr=1 OR*/
       DJ2_pr=1 OR DJ4_pr=1 OR DJ6_pr=1 OR DJ8_pr=1 OR /*DF2_pr=1 OR*/
       DN1_pr=1 OR DL1_pr=1 OR DE1_pr=1 OR DE2_pr=1 OR DH4_pr=1 OR
       DC1_pr=1 OR DC2_pr=1 OR DC3_pr=1 OR DC4_pr=1 OR DC5_pr=1 OR
       DC6_pr=1 OR DC7_pr=1 OR DC11_pr=1 OR DC12_pr=1 OR
       DK8_pr=1 OR DK9_pr=1 OR DK4_pr=1 OR
       HE_PFTtr=1 OR BP17_dg=1 THEN chronic_disease=1;
                               ELSE chronic_disease=0;

    /* 규칙적인 운동(regular_workout: 규칙적인 운동X(0), 규칙적인 운동O(1) */
    IF BE3_72 < 8 THEN DO;
        IF BE3_82 < 8 AND (BE3_72 + BE3_82) >= 2 THEN
            regular_workout=1;
        ELSE IF BE3_72 >= 2 THEN
            regular_workout=1;
        ELSE
            regular_workout=0;
        END;
    ELSE IF BE3_82 < 8 AND BE3_82 >= 2 THEN
        regular_workout=1;
    ELSE
        regular_workout=0;

    /* 수면시간(sleep_length: 6시간 미만(1), 6~9시간 미만(2), 9시간 이상(3)) */
    IF total_slp_wd = . THEN
        sleep_average_h = ROUND(total_slp_wk / 60, 1);
    ELSE
        sleep_average_h = ROUND((total_slp_wk*5 + total_slp_wd*2) / (7*60), 1);

    IF sleep_average_h < 6 THEN      sleep_length=1;
    ELSE IF sleep_average_h < 9 THEN sleep_length=2;
    ELSE IF sleep_average_h >=9 THEN sleep_length=3;

    /* 나이그룹(age_group: 20~29(2), 30~39(3), 40~49(4), 50~59(5)) */
    IF 20<=age<=29 THEN age_group=2;
    ELSE IF study_in=1 and 30<=age<=39 THEN age_group=3;
    ELSE IF study_in=1 and 40<=age<=49 THEN age_group=4;
    ELSE IF study_in=1 and 50<=age<=59 THEN age_group=5;
    ELSE age_group=.;

    /* 거주지(town: 동(1), 읍면(2)) */
    IF town_t=1 THEN town=1;
    ELSE IF town_t=2 THEN town=2;
    ELSE town=.;

    /* 결혼상태(martial_status: 유배우자, 동거(1), 별거/사별/이혼(2), 미혼(3), 응답거부(4) */
    IF marri_1 = 2 OR marri_2 = 88 THEN martial_status = 3;
    ELSE IF marri_2 = 1            THEN martial_status = 1;
    ELSE IF marri_2 IN (2, 3, 4)   THEN martial_status = 2;
    ELSE IF marri_2 = 8            THEN martial_status = 4;
    ELSE martial_status = .;

    /* 취업형태(occupation_type: 비취업/무급가족종사자(1), 자영업자와 고용주(2),
     *                          임금근로자(정규직)(3), 임금근로자(비정규직)(4) */
    IF EC1_1 = 2             THEN occupation_type = 1;
    ELSE IF EC1_1 = 1 THEN DO;
      IF EC_stt_1 = 2        THEN occupation_type = 2;
      ELSE IF EC_stt_1 = 3  THEN occupation_type =1;
      ELSE IF EC_stt_1 = 1 THEN DO;
        IF EC_wht_0 = 1      THEN occupation_type = 3;
        ELSE IF EC_wht_0 = 2 THEN occupation_type = 4;
      END;
    END;

    /* 교육수준(edu_1: 중졸이하(1), 고졸(2), 대졸이상(3)) */
    IF edu=1 THEN edu_1=1;
    ELSE IF edu=2 THEN edu_1=1;
    ELSE IF edu=3 THEN edu_1=2;
    ELSE IF edu=4 THEN edu_1=3;
    ELSE IF edu_1=.;

    /* 가계소득(income(소득4분위 기준): 하(1), 중하(2), 중상(3), 상(4)) */
    IF ho_incm=1 THEN income=1;
    ELSE IF ho_incm=2 THEN income=2;
    ELSE IF ho_incm=3 THEN income=3;
    ELSE IF ho_incm=4 THEN income=4;
    ELSE income=.;
RUN;

DATA &DATA_STUDY_READY;
    SET &DATA_STUDY_READY;
    IF phq_in = 1 THEN DO;
        IF mh_phq_s < 10 THEN PHQ = 0;
                         ELSE PHQ = 1;
    END;
RUN;

PROC FREQ DATA=&DATA_STUDY_READY;
    TABLE age_group town martial_status edu_1 occupation_type income
          chronic_disease regular_workout sleep_length
          C_sm1 acl1 grp1 ;
RUN;
%MEND;

*%DO_DATA_RAW;
*%DO_DATA_KEEP;
%DO_STUDY_SELECTION;
%DO_STUDY_READY;
