/*************************************************************************************************************************************************************
		- Author: Gabriella Wong
		- Last update: 15 mar 2019
		- Purpose: Look for attrition at students and parents level
		- Data source: Jadenka baseline data collection
		- Windows version
		- Worked on Stata 14.0
*************************************************************************************************************************************************************/

clear all
set more off, permanently
set scheme burd4


*  Roots 
	global root 				"D:\Box Sync\Panama Math"
	global analisis 			"$root\10_Analysis&Results\01 Data analysis" 
	
* DATA
	global dat 					"$analisis\data"
* raw data before cleaning
	global raw 					"$dat\raw\BL" 
* cleaned data
	global dta 					"$dat\dta"
*  table 
	global tab 					"$analisis\results\tables"
* Balance_test
	global balance 				"$tab\Balance_test"
* Descriptive statistics	
	global des 					"$tab\Descriptive_statistics"	
* temp files
	global temp 				"$tab\temp"
	
	
* DBs
* Baseline students
	global baseline 			"$dta\BL\Estudiantes_BL_prep.dta" 
* Endline students
	global endline 				"$dta\EL\Estudiantes_EL_prep.dta" 
* Principals database
	global director				"$dta\BL\Directores_BL_prep.dta"
* Clean endline students
	global endline_clean 		"$dta\EL\Estudiantes_EL_clean.dta"
* Parents
	global padres 				"$dta\BL\Padres_BL_prep.dta"
* Admin data
	global admin 				"$dat\raw\complementary\muestra_aleatorizada_032018.dta"	
	
	
*PENDING - EXPLICAR MEJOR LOS MERGE

/*******************************************************************************
(1) ATTRITION TEST MODEL
*******************************************************************************/	

u "$baseline", clear

	drop  duracion escuela
	rename consent consent_bl
	

	merge 1:m id_nino using "$endline_clean", keepusing(id_nino consent) //endline_clean (we need not-consented as well)
	drop if _merge==2 
	
	eststo clear

	/*gen No-Linea-Final indicator*/ 
		gen NLF=0
		replace NLF=1 if consent==. | consent==0 // baseline students that didn't enroll in endline
		
	/* Treated students found in LF  */
		gen SLF=0
		replace SLF=1 if consent==1	& treatment!=0 // participantes LF y tratados
		
	/* Treated students not found in LF */
	gen NLF2=0
	replace NLF2 =1 if consent==. | consent==0 & treatment!=0 //  no participantes tratados

/* -------------------------------------------------------------------------- */ 		
		
*1) Cuadro: Analisis de desgaste

		
	/*  Modelo 1: NLF = c + B x (tratamiento) + e	 */
		eststo: reg NLF i.treatment, vce(cluster escuela_num)

	/*  Modelo 2: NLF = c + B x (sexo) + e */
		eststo: reg NLF sex, vce(cluster escuela_num)

	/* Modelo 3: NLF = x + B1 x (sexo) + B2 x(sexo)x (treat) */
		eststo: reg NLF i.treatment sex i.treatment#sex,  vce(cluster escuela_num)

	/* Modelo 4: NLF = c + B x (tipo) + e */

		eststo: reg NLF i.prek_tipo, vce(cluster escuela_num)

	/* Modelo 5: NLF = x + B1 x (tipo) + B2 x(tipo)x (treat) */
		eststo: reg NLF i.treatment i.prek_tipo i.treatment#i.prek_tipo,  vce(cluster escuela_num)

	/* Modelo 6: NLF = c + B x (zona) + e */
		eststo: reg NLF zone, vce(cluster escuela_num) // esta sale signiticativo, pero make no sense porque no esperábamos tener 50% comarca y 50% no comarca. 

	/* Modelo 7: NLF = x + B1 x (zona) + B2 x(zona)x (treat) */
		eststo: reg NLF i.treatment zone i.treatment#zone,  vce(cluster escuela_num)

		
				esttab using "$temp/Desgaste_estudiantes.csv", replace plain  label b(%10.3f) ///
				star nobaselevels scalars("Control") mtitles("M1" "M2" "M3" "M4" "M5" "M6" "M7" ) interaction(" ") ///
				nocons drop(*treatment#*)  se
				
				
				* Export to general general findings *
				preserve	
					import delimited "$temp\Desgaste_estudiantes.csv",  encoding(utf8) clear
					export excel using "$balance\Attrition_test.xls", sheet("Attrition_estudiantes") sheetmodify cell(A2)
				restore

				
				
				esttab using "$temp/Desgaste_estudiantes.csv", replace plain  label b(%10.3f) ///
				star nobaselevels scalars("Control") mtitles("M1" "M2" "M3" "M4" "M5" "M6" "M7" ) interaction(" ") ///
				nocons   se				

				* Export to general general findings * ANNEX
				preserve	
					import delimited "$temp\Desgaste_estudiantes.csv",  encoding(utf8) clear
					export excel using "$balance\Attrition_test.xls", sheet("Attrition_estu_des") sheetmodify cell(A2)
				restore			
				
		
	
/*******************************************************************************
(2)	ATTRITION TEST given BASELINE score
*******************************************************************************/	
	
	global effect  "_egma_z _egra_z  _egra_ngb_z _etnomate_z _cultura_z _percepciones_z"
			
	eststo clear

	foreach var in $effect			 {	
		
	
			* Control BL y estratos *
			eststo:	reg bl`var' NLF NLF2 SLF  i.strata		, vce(cluster escuela_num) 
	
	
					esttab using "$temp/Desgaste_estudiantes.csv", replace label b(%10.3f) plain ///
					star(+ 0.10 * 0.05 ** 0.01 *** 0.001) nobaselevels mtitles("Matemática" "Comprensión lectora" "C. lectora en ngäbere" "Etnomatemáticas" "Id. Cultural" "Percepciones mate")  ///
					drop(*.strata) nocons note se

					
					* Export to general results *
					preserve	
						import delimited "$temp\Desgaste_estudiantes.csv", encoding(utf8) clear
						export excel using "$balance\Attrition_test.xls", sheet("Attrition_estu_BL") sheetmodify cell(A2)
					restore	
				
	}	
	*			
			
			

/*************************************************************************************************************************************************************
(3) ORTOGONALIDAD - ENDLINE CON DATA BASELINE
*************************************************************************************************************************************************************/

u "$baseline", clear
	drop  duracion escuela

	merge 1:1 id_nino using "$endline", keepusing(id_nino el_strata*)
	keep if _merge==3
	*_merge=2 * son niños falsos borrados en baseline, pero todavia no en endline
	drop _merge

	global vars "sex time_elapsed nr bl_egma_z bl_ansiedad_z bl_egra_z bl_egra_ngb_z bl_etnomate_z bl_cultura_z bl_ngabe" // SD scores

				orth_out $vars using "$temp\temp.dta" ,  by(treatment) pcompare test count  vce(cluster escuela_num) ///
				armlabel("Control" "Tratamiento Bilingüe" "Tratamiento Intercultural") replace stars dta  ///
				notes(Las pruebas corrigen por errores estándar clusterizados. Todos los puntajes se encuetran en desviaciones estándar.) 
				
				orth_out $vars using "$temp\temp1.dta" ,  by(treatment) ///
				pcompare test count covariates(el_strata1-el_strata16) vce(cluster escuela_num) /// 
				armlabel("Control" "Tratamiento Bilingüe" "Tratamiento Intercultural") replace stars dta  ///
				notes(Todas tlas pruebas de ortogonalidad controlan por efectos fijos por los estratos de aleatorización (área geográfica y tipo de grado). Todos los puntajes se encuentran estandarizadas) 
	

				preserve
						u "$temp\temp.dta", clear
						drop in 1
						replace H = "P-value" in 1
						replace A = "Proporción de mujeres" in 2
						replace A = "Duración" in 3
						replace A = "# de 'No respondió' por encuesta" in 4
						replace A = "Puntaje en matemáticas" in 5
						replace A = "índice en ansiedad" in 6
						replace A = "Puntaje en EGRA en español" in 7
						replace A = "Puntaje en EGRA en ngabere" in 8
						replace A = "Puntaje en etnomatemáticas" in 9
						replace A = "Puntaje en identidad cultural"  in 10
						replace A = "% de niños identificados como NGABE" in 11
						compress
						
						export excel using "$balance\Attrition_test.xls", sheet("1 Balance_EL_data_BL") sheetmodify cell(A2) 
					
				restore
					
				preserve
						u "$temp\temp1.dta", clear
						drop in 1
						replace H = "P-value" in 1
						replace A = "Proporción de mujeres" in 2
						replace A = "Duración" in 3
						replace A = "# de 'No respondió' por encuesta" in 4
						replace A = "Puntaje en matemáticas" in 5
						replace A = "índice en ansiedad" in 6
						replace A = "Puntaje en EGRA en español" in 7
						replace A = "Puntaje en EGRA en ngabere" in 8
						replace A = "Puntaje en etnomatemáticas" in 9
						replace A = "Puntaje en identidad cultural"  in 10
						replace A = "% de niños identificados como NGABE" in 11

						compress
						
						export excel using "$balance\Attrition_test.xls", sheet("1 Balance_EL_data_BL") sheetmodify cell(A20) 
				restore
							

/*************************************************************************************************************************************************************
(4) ORTOGONALIDAD - ENDLINE CON DATA ENDLINE
*************************************************************************************************************************************************************/

 
use "$endline", clear
				
		global vars2 "gender time_elapsed nr el_egma_z el_ansiedad_z el_egra_z el_egra_ngb_z el_etnomate_z el_cultura_z el_ngabe" 

		
				orth_out $vars2 using "$temp\temp3.dta" ,  by(treatment) pcompare test count  vce(cluster escuela_num) ///
				armlabel("Control" "Tratamiento Bilingüe" "Tratamiento Intercultural") replace stars dta  ///
				notes(Las pruebas corrigen por errores estándar clusterizados. Todos los puntajes se encuetran en desviaciones estándar.) 
				
				orth_out $vars2 using "$temp\temp4.dta" ,  by(treatment) ///
				pcompare test count covariates(el_strata1-el_strata16) vce(cluster escuela_num) /// 
				armlabel("Control" "Tratamiento Bilingüe" "Tratamiento Intercultural") replace stars dta  ///
				notes(Todas tlas pruebas de ortogonalidad controlan por efectos fijos por los estratos de aleatorización (área geográfica y tipo de grado). Todos los puntajes se encuentran estandarizadas) 
	
		

		preserve
				u "$temp\temp3.dta", clear
				drop in 1
				replace H = "P-value" in 1
				replace A = "Proporción de mujeres" in 2
				replace A = "Duración" in 3
				replace A = "# de 'No respondió' por encuesta" in 4
				replace A = "Puntaje en matemáticas" in 5
				replace A = "índice en ansiedad" in 6
				replace A = "Puntaje en EGRA en español" in 7
				replace A = "Puntaje en EGRA en ngabere" in 8
				replace A = "Puntaje en etnomatemáticas" in 9
				replace A = "Puntaje en identidad cultural"  in 10
				*replace A = "% de niños identificados como NGABE" in 11
				compress
				
				export excel using "$balance\Attrition_test.xls", sheet("2 Balance_EL_data_EL") sheetmodify cell(A2) 
			
		restore
			
		preserve
				u "$temp\temp4.dta", clear
				drop in 1
				replace H = "P-value" in 1
				replace A = "Proporción de mujeres" in 2
				replace A = "Duración" in 3
				replace A = "# de 'No respondió' por encuesta" in 4
				replace A = "Puntaje en matemáticas" in 5
				replace A = "índice en ansiedad" in 6
				replace A = "Puntaje en EGRA en español" in 7
				replace A = "Puntaje en EGRA en ngabere" in 8
				replace A = "Puntaje en etnomatemáticas" in 9
				replace A = "Puntaje en identidad cultural"  in 10
				*replace A = "% de niños identificados como NGABE" in 11

				compress
				
				export excel using "$balance\Attrition_test.xls", sheet("2 Balance_EL_data_EL") sheetmodify cell(A20) 
		restore
		
		
	*/					
		
				orth_out $vars2 using "$temp\temp5.dta", by(pool) ///
				compare test count covariates(el_strata1-el_strata16) vce(cluster escuela_num) /// 
				armlabel("Control" "Tratamiento") replace stars dta  ///
				notes( Controles: efectos fijos por estratos de aleatorización (área geográfica y tipo de grado)) 
			
			preserve
				u "$temp\temp5.dta", clear
				drop in 1
				replace E = "P-value" in 1
				replace A = "Proporción de mujeres" in 2
				replace A = "Duración" in 3
				replace A = "# de 'No respondió' por encuesta" in 4
				replace A = "Puntaje en matemáticas" in 5
				replace A = "índice en ansiedad" in 6
				replace A = "Puntaje en EGRA en español" in 7
				replace A = "Puntaje en EGRA en ngabere" in 8
				replace A = "Puntaje en etnomatemáticas" in 9
				replace A = "Puntaje en identidad cultural"  in 10
				*replace A = "% de niños identificados como NGABE" in 11
				compress
				
						export excel using "$balance\Attrition_test.xls", sheet("3_balance_EL_pool") sheetmodify cell(A2) 
			
			restore	

		/* delete unwanted DTAs */	
		erase 	"$temp\temp1.dta"
		*erase 	"$temp\temp2.dta"
		erase 	"$temp\temp3.dta"
		erase 	"$temp\temp4.dta"
		erase 	"$temp\temp5.dta"
		


/*************************************************************************************************************************************************************
(5) ORTOGONALIDAD - DATA ESCUELAS CON ESCUELAS ENDLINE
*************************************************************************************************************************************************************/

* Orthogonality test eststo: regarding schools characteristics	

use "$endline", clear


	bysort escuela_num: gen n=_n
	keep if n==1
	keep escuela_num el_strata*

	merge 1:1 escuela_num using "$director"
	keep if _merge==3


	global escuela  s1_p2 turno s1_p8 ///
	lengua_escuela* formal cefacei prejardin jardin  s3_p29 s3_p30 ///
	s3_p31 s3_p32 s3_p33 agua luz comunicacion internet sanitario s3_p39 
		
			preserve
				orth_out $escuela using "$temp\temp.dta" ,  by(treatment) ///
				test count covariates(strata1-strata16) vce(cluster escuela_num) /// 
				armlabel("Control" "Tratamiento Bilingüe" "Tratamiento Intercultural") replace stars dta  ///
				notes(Todas las pruebas de ortogonalidad controlan por efectos fijos por los estratos de aleatorización (área geográfica y tipo de grado)) 
				
				u "$temp\temp.dta", clear
				drop in 1
				replace E = "P-value" in 1
				replace A = "Unigrado" in 2
				replace A = "Número de turnos" in 3
				replace A = "Maestros formados en EIB" in 4
				replace A = "Escuela con educación inicial Formal" in 8
				replace A = "Modalidad: CEFACEI" in 9				
				replace A = "Modalidad: Pre-jardín" in 10
				replace A = "Modalidad: Jardín"  in 11
				replace A = "Escuela construída con fines educativos" in 12
				replace A = "Material de la escuela" in 13
				replace A = "Material de las aulas de preescolar" in 14
				replace A = "Material de las aulas de CEFACEI" in 15
				replace A = "CEFACEI comparte misma infraestructura de la escuela" in 16
				replace A = "Suministro de agua" in 17				
				replace A = "Suministro de luz" in 18
				replace A = "Suministro de comunicación" in 19
				replace A = "Suministro de internet" in 20
				replace A = "Suministro de servicio sanitario" in 21
				replace A = "Infraestructura compartida con otros establecimientos" in 22
				
				compress
		
					export excel using "$balance\Attrition_test.xls", sheet("4 school_balance") sheetmodify cell(A2) 
			restore
			
			
* 12.1 Balance - School characteristics POOL * 

			
			preserve
				orth_out $escuela using "$temp\temp.dta" ,  by(pool) ///
				compare test count covariates(strata1-strata16) vce(cluster escuela_num) /// 
				armlabel("Control" "Tratamiento") replace stars dta  ///
				notes(Todas las pruebas de ortogonalidad controlan por efectos fijos por los estratos de aleatorización (área geográfica y tipo de grado)) 
				
				u "$temp\temp.dta", clear
				drop in 1
				replace E = "P-value" in 1
				replace A = "Unigrado" in 2
				replace A = "Número de turnos" in 3
				replace A = "Maestros formados en EIB" in 4
				replace A = "Escuela con educación inicial Formal" in 8
				replace A = "Modalidad: CEFACEI" in 9				
				replace A = "Modalidad: Pre-jardín" in 10
				replace A = "Modalidad: Jardín"  in 11
				replace A = "Escuela construída con fines educativos" in 12
				replace A = "Material de la escuela" in 13
				replace A = "Material de las aulas de preescolar" in 14
				replace A = "Material de las aulas de CEFACEI" in 15
				replace A = "CEFACEI comparte misma infraestructura de la escuela" in 16
				replace A = "Suministro de agua" in 17				
				replace A = "Suministro de luz" in 18
				replace A = "Suministro de comunicación" in 19
				replace A = "Suministro de internet" in 20
				replace A = "Suministro de servicio sanitario" in 21
				replace A = "Infraestructura compartida con otros establecimientos" in 22
				
				compress
		
					export excel using "$balance\Attrition_test.xls", sheet("5 school_balance_pool") sheetmodify cell(A2) 
			restore			
			

/*************************************************************************************************************************************************************
(5) ORTOGONALIDAD - ADMIN DATA  CON ESCUELAS ENDLINE
*************************************************************************************************************************************************************/		


	local cov r_area r_distrito r_corregimiento r_area_mgmt preescolar prek_tipo prek_formal prek_noformal prek_ngabe ngb_formal ngb_noformal    ///
	light luz solar madera concreto material base cocina agua huerta letrina sanitario 
	
	local base1 formal_h formal_m noformal_h noformal_m  


	
use "$endline", clear


	bysort escuela_num: gen n=_n
	keep if n==1
	keep escuela_num
	rename escuela_num id

	merge 1:1 id using "$admin", keepusing(`cov' `base1' id treatment)
			
	orth_out `cov' `base1' using "$balance\Attrition_test.xls", by(treatment) ///
	sheet("6 admin_data_EL") overall count se test stars sheetmodify  

	
/*************************************************************************************************************************************************************

	 DESGASTE DEVOLUCION DE CUESTIONARIOS PADRES

*************************************************************************************************************************************************************/		
	

/*******************************************************************************
(1)  Probabilidad de no devolver cuestionarios dado TREATMENT
*******************************************************************************/	

u "$baseline", clear

	  
	rename consent consent_bl

	merge 1:m id_nino using "$padres", keepusing(id_nino pad_consent) //endline_clean (we need not-consented as well)
	drop if _merge==2 // estudiantes falsos que eliminamos ya de baseline data
	
	eststo clear

	
	/* gen No-Devolvio-Cuestionario indicator*/ 
		gen NDC=0
		replace NDC=1 if _merge!=3  // parents that didnt return the survey
		
	/*  gen Cuestionario completo indicator  */
		gen SDC =0
		replace SDC=1 if pad_consent==1
	
/* ---------------------------------------------------------------------------*/	
				
	/*  Modelo 1: NDC = c + B x (tratamiento) + e	 */
		eststo: reg NDC i.treatment, vce(cluster escuela_num)

	/*  Modelo 2: NDC = c + B x (sexo) + e */
		eststo: reg NDC sex, vce(cluster escuela_num)

	/* Modelo 3: NDC = x + B1 x (sexo) + B2 x(sexo)x (treat) */
		eststo: reg NDC i.treatment sex i.treatment#sex,  vce(cluster escuela_num)

	/* Modelo 4: NDC = c + B x (tipo) + e */
		eststo: reg NDC i.prek_tipo, vce(cluster escuela_num)

	/* Modelo 5: NDC = x + B1 x (tipo) + B2 x(tipo)x (treat) */
		eststo: reg NDC i.treatment i.prek_tipo i.treatment#i.prek_tipo,  vce(cluster escuela_num)

	/* Modelo 6: NDC = c + B x (zona) + e */
		eststo: reg NDC zone, vce(cluster escuela_num) // esta sale signiticativo, pero make no sense porque no esperábamos tener 50% comarca y 50% no comarca. 

	/* Modelo 7: NDC = x + B1 x (zona) + B2 x(zona)x (treat) */
		eststo: reg NDC i.treatment zone ib0.treatment#zone,  vce(cluster escuela_num)


				esttab using "$temp/Desgaste_padres.csv", replace plain  label b(%10.3f) ///
				star nobaselevels scalars("Control") mtitles("M1" "M2" "M3" "M4" "M5" "M6" "M7" ) interaction(" ") ///
				nocons drop(*.treatment#*) se
							
				
				* Export to general general findings *
				preserve	
					import delimited "$temp\Desgaste_padres.csv",  encoding(utf8) clear
					export excel using "$balance\Attrition_test.xls", sheet("Attrition_padres") sheetmodify cell(A2)
				restore
						
		

/*******************************************************************************
	Relación con el desgaste de los padres y el nivel inicial de estudiantes
	
*******************************************************************************/				
		

	global effect  "_egma_z _egra_z  _egra_ngb_z _etnomate_z _cultura_z _percepciones_z"
			
	eststo clear

	foreach var in $effect			 {	
		
	
			* Control BL y estratos *
			eststo:	reg bl`var' SDC  i.strata		, vce(cluster escuela_num) 
	
	
					esttab using "$temp/Desgaste_padres.csv", replace label b(%10.3f) plain ///
					star(+ 0.10 * 0.05 ** 0.01 *** 0.001) nobaselevels mtitles("Matemática" "Comprensión lectora" "C. lectora en ngäbere" "Etnomatemáticas" "Id. Cultural" "Percepciones mate")  ///
					drop(*.strata) nocons note se

					
					* Export to general results *
					preserve	
						import delimited "$temp\Desgaste_padres.csv", encoding(utf8) clear
						export excel using "$balance\Attrition_test.xls", sheet("Attrition_padres_BL") sheetmodify cell(A2)
					restore	
				
	}	
	*			
								
			
	* Delete unnecesary dtas *	
	erase "$temp\temp.dta" 

	
		** THE END **
