/*******************************************************************************
		- Author: Gabriella Wong
		- Last update: 12 march 2019
		- Purpose: Clean baseline data before analysis
		- Data source: Jadenka baseline data collection
		- Windows version
		- Worked on Stata 14
		- Reviewed by Juan
*******************************************************************************/
clear all
set more off
set scheme burd4

*Roots
	global root  		"D:\Box Sync\Panama Math"
	*global root    	"C:\Users\IPAuser\Box Sync"
	*global root  		"C:\Users\JHernandez\Box Sync\IPA_PER_Projects\Active\Panama Math"  //Juan
	global analisis 	"$root\10_Analysis&Results\01 Data analysis" 
	
* DATA
	global dat 			"$analisis\data"
* raw data before cleaning
	global raw 			"$dat\raw\BL" 
* cleaned data
	global dta 			"$dat\dta\BL"	
* temp files
	global temp		 	"$dta\temp"

* DBs
*Cleaned students
	global estudiantes  "$dta\Estudiantes_BL_clean.dta" 
* paper survey conteo
	global papel 		"$root\07_Questionnaires&Data\Baseline_Quant\02_DataCollection\02 Quality control plan\00 High-Frequency Checks\02_output"
* treatment assignment
	global random_smpl 	"$analisis\data\raw\complementary\muestra_aleatorizada_032018"
* complements
	global endline 		"$analisis\data\raw\complementary"

********************************************************************************

/*******************************************************************************
RECOVERING ASSIGNMENT
********************************************************************************/
				
u "$random_smpl", clear

		sort id
		rename id escuela_num
		recast int escuela_num
		label variable escuela_num
		label values escuela_num escuela_num
		label var r_area "Área geográfica"
		keep escuela_num treatment area r_area zona prek_tipo // copy treatment assignment
		keep escuela_num treatment area r_area zona prek_tipo 	
		
			*relabel r_area
			la def r_area 6 "ÑO KRIBO",modify
			la val r_area r_area
		
		
		merge 1:m escuela_num using "$estudiantes" //6 school were originally randomized but we do not have baseline data on them
		
		gen NLB = 0
		replace NLB = 1 if _merge == 1
		drop if consent==0  //for analysis, we just want to keep those with consent.
				
		keep if _merge==3 // we only keep those that matched  	
		drop _merge 					
											
* Survey duration*
	*Overall*
	destring duracion, replace
	g time_elapsed = duracion/60

	tab time_elapsed  
	su time_elapsed , de
	global median = (round(`r(p50)',.1))
	global avg = (round(`r(mean)',.1))
	global max = (round(`r(max)',.1)) 
	global min = (round(`r(min)',.1))

										
/*******************************************************************************
 1. PREPPING DATA
********************************************************************************/					

*******************"No respondio"***********************************************
// No response question must be marked as zero points
	gen nr = 0
		foreach var in s1_e1 s1_e2 s2_e1 s2_e2 s3_e1 s3_e2 s3_e3 s4_e1 s5_e1 s5_e2 s5_e3 s5_e4 s7_e1 s7_e2 s8_e1 s8_e2 s9_e1 s9_e2 s9_e3 s9_e4 s10_e1 s10_e2 s10_e3 s10_e4 s12_e1 s12_e2 s12_e3 s12_e4 s12_e5 s13_e1 s13_e2 s13_e3 s14_e1 s14_e2 s14_e3 s15_e1 s15_e2 s16_e1 s16_e2 s17_e1 s17_e2 s21_e1 s21_e2 s22_e1 s22_e2 s22_e3 s22_e4 kra nagua jeki ansiedad1 ansiedad2 ansiedad3 ansiedad4 ansiedad5 ansiedad6 {
			replace nr = nr + 1 if `var'==99
		}

/*******************************************************************************
 0. CHILDREN'S PROFILE
********************************************************************************/

// Ethnia reported by teacher 
	g bl_ngabe=ngabe_ident // # niños ngabe encuestados

// The first two days of baseline we only interviewed NGABE children 
//(that was the very first strategy of the baseline, then we had to change, 
// as we faced difficulties finding just ngabe children in nearby areas)
	replace bl_ngabe=1 if date==date("23apr2018", "DMY") | date==date("24apr2018", "DMY") 
	la var bl_ngabe "Estudiante ngäbe"	


	g bl_latino=. // # niños latinos encuestados
		replace bl_latino=1 if ngabe_ident==0 // Issue: los tres primeros días la var estaba como not required. Por eso, 22 encuestas no se llenaron
		replace bl_latino=0 if ngabe_ident==1
		replace bl_latino=0 if bl_ngabe==1

// Children's language preference in school (for balance)
// reported by the teacher
	tab lengua_profe , g(lp)
	la var lengua_profe "Idioma en el que niño se desenvuelve mejor"

// Ethnia reported by surveyor
// We wanted to compare the ethnia reported by teacher and double check it w/ the surveyor
	tab ngabe_encuestador, g(ne)
	la var ngabe_encuestador "El encuestador/considera que el estudiante es Ngäbe"

// why the surveyor thinks the children is ngabe or not
	la var ngabe_why_1 "El niño/a tiene rasgos ngäbe"
	la var ngabe_why_2 "El niño/a tiene apellidos ngäbe" 
	la var ngabe_why_3 "Por su vestimenta" 
	la var ngabe_why_4 "No lo sé" 
	la var ngabe_why_99 "Otros"

// Language reported by children
	tab lengua_estud, g(le)
	la var lengua_estud "Idioma que habla en su casa"

// language test 1 (we can only know with this that he/she understands ngabere)
	gen nom_ngb =0
		replace nom_ngb=1 if name_ngb==1

// language test 2
	gen ed_ngb=0
		replace ed_ngb=1 if age_ngb==1

// overall language test
	gen ngabere=nom_ngb+ed_ngb

// section done in ngabere or spanish (identidad cultural)
	tab lenguaje6 , g(lic)
	la var lenguaje6 "Idioma en el que se hizo seccion Id. cultural"

// section done in ngabere or spanish (percepciones)
	tab lenguaje7, g(lepe) 
	la var lenguaje7 "Idioma en el que se hizo seccion Percepciones"

// Language reported by teacher (for graph)
	gen idioma=lengua_profe
		replace idioma=99 if lengua_profe>2 
		replace idioma=3 if lengua_profe==4
		la def lang 1 "Español" 2 "Ngabere" 3 "Ambos" 99 "Otros"
		la val idioma lang
	
// Student AGE
	
	tab edad1
	replace edad1=. if edad1==91 | edad1==110 | edad1==2711

	tab edad2
	replace edad2=. if edad2==-11 | edad2==13 | edad2==15 | edad2==31

	gen edad4=.
	replace edad4=edad3 if edad3==2 | edad3==4 | edad3==5 | edad3==8
		
	tab edad3
	replace edad3=. if edad3==0 | edad3==4 | edad3==5 | edad3==8 | edad3==201 
	replace edad3=2012 if edad3==1012 | edad3==2021  | edad3==2812  | edad3==20012 | edad3==12
	replace edad3=2013 if edad3==1013 | edad3==3013 | edad3==20123 | edad3==13
	replace edad3=2011 if  edad3==11
	replace edad3=2014 if  edad3==14 | edad3==214
	replace edad3=2015 if  edad3==15
	replace edad3=2017 if  edad3==17
	replace edad3=2016 if  edad3==2

		global actual "2018"
			gen age = $actual - edad3
				sum age, detail
				return list

		global nueve "r(p99)"
		replace age =. if age > $nueve	

//	Tipo de grado
	label define tipo3 1 "Pre-Jardín" 2 "Jardín" 3 "CEFACEI" 99 "Otros (especifique)"
	label values tipo tipo3
	rename tipo prek_tipo_bl
	
/*******************************************************************************
/*******************************************************************************
								
								RAW SCORE
		Purpose: make descriptive graphs for slides and reports				
								
********************************************************************************/
********************************************************************************/

/*******************************************************************************
 2. EGMA
********************************************************************************/
// Un estudiante se puede sacar como máximo 34 en EGMA


*EGMA GLOBALS

		global s1 "s1_e1 s1_e2" // Espacialidad y Medidas (Tamaños) - 2ptos
		global s2 "s2_e1 s2_e2" // Espacialidad y Medidas (Arriba-Abajo, Dentro, Fuera) - 2pts
	    global s3 "s3_e1 s3_e2 s3_e3" // Discriminación de cantidades (Más,Menos,Igual) - 3 ptos
		global s4 "s4_e1" // Discriminación de cantidades (Más,Menos,Igual) - 1 pto
		global s5 "s5_e1 s5_e2 s5_e3 s5_e4" //Reconocer figuras - 4 ptos
		global s6 "s6_e1 s6_e2" // Conteo oral - 3 ptos
		global s7 "s7_e1 s7_e2 s7_e3" // Contar objetos 1 (EGMA) - 1 ptos
		global s8 "s8_e1 s8_e2 s8_e3" // Contar objetos 2 (EGMA) - 1 ptos
		global s9 "s9_e1 s9_e2 s9_e3 s9_e4" // Seleccion de números - 4 ptos
		global s10 "s10_e1 s10_e2 s10_e3 s10_e4" // Seleccion de numero 2 - 4 ptos
		global s11 "s11_e1" // Nombrar números - 4 ptos
		global s12 "s12_e1 s12_e2 s12_e3 s12_e4 s12_e5" // sumar y restar - 5ptos
				

			foreach var of varlist $s1 $s2 $s3 $s4 $s5 $s6 $s9 $s10 {
			*foreach var of varlist $s1 $s2 $s3 $s4 $s5 $s6 s7_e2 $s9 $s10 $s12 $s8 // en caso se cambie el "88"
				replace `var'=0 if `var'==99 
				replace `var'=0 if `var'==.  //No response = 0 points
				*replace `var'=0 if `var'==88
			}
			*
														
*EGMA SCORE
		gen bl_math_score= 0

			foreach var of varlist $s1 $s2 $s3 $s4 $s5 $s9 $s10 { 
				label var `var' ""
				replace bl_math_score = bl_math_score + 1 if `var'==1 // s2,3,4,5,6,10,11
			}
			*
						
			// conteo oral
				xtile terciles = s6_e1 if s6_e1 != 0 & s6_e1 != ., nq(3)   // For descriptive we assign points according to position in distribution
				tab s6_e1 terciles, m   
				/* 0 are penalised as with no score, we avoid also counting missings
				 terciles are not exact due to discrete nature of data and the skewed distribution to the right see
				  histogram s6_e1 */
							
				replace bl_math_score = bl_math_score + 3 if tercile == 3 
				replace bl_math_score = bl_math_score + 2 if tercile == 2
				replace bl_math_score = bl_math_score + 1 if tercile == 1 
													
			// contar objetos 1	
			*** OBJ. Contar  el número, no indicar cuántos hay. Entender a mayor detalle hab. "cuántos hay"
				*replace bl_math_score = bl_math_score + 1 if s7_e1 == 4 
				replace bl_math_score = bl_math_score + 1 if s7_e2 == 4 
					
			// contar objetos 2	
				*replace bl_math_score = bl_math_score + 1 if s8_e1 == 12 
				replace bl_math_score = bl_math_score + 1 if s8_e2 == 12 
						
				* s7_e1 y s8_e1 es indicar "cuántos hay" - no va dentro del análisis porque el task es contar objetos.
						
			// Nombrar números
				gen s11_total = s11_e1_1 + s11_e1_2 + s11_e1_3 + s11_e1_4 + s11_e1_5 + s11_e1_6 + s11_e1_7 + s11_e1_8 + s11_e1_9 +s11_e1_10 + s11_e1_11 + s11_e1_12 
					replace bl_math_score = 0 if s11_total==. 
					replace bl_math_score = bl_math_score + 1 if s11_total>9 
					replace bl_math_score = bl_math_score + 1 if s11_total>6 
					replace bl_math_score = bl_math_score + 1 if s11_total>3 
					replace bl_math_score = bl_math_score + 1 if s11_total>0 						
						
					* Actualizar excel puntuaciones 
						
			// sumar y restar
				replace bl_math_score = bl_math_score + 1 if s12_e1==3 
				replace bl_math_score = bl_math_score + 1 if s12_e2==4
				replace bl_math_score = bl_math_score + 1 if s12_e3==1
				replace bl_math_score = bl_math_score + 1 if s12_e4==2
				replace bl_math_score = bl_math_score + 1 if s12_e5==3  
						

* EGMA desagregado para gráfico baseline *

// Medidas : bt1
// Espacialidad : bt2
// Discriminacion de cantidades: bt3
// Conteo oral: Convertir como raw-score (oral_count)
// Conteo de objetos : bt6 + bt7 / Convertir como raw-score (1pto) (obj_count)
// Seleccion de numeros: bt8 + bt9
// Nombrar números: bt10 
// Sumar y restar: bt11

	/*
			gen bl_oral_count = 0 // conteo oral
					replace bl_oral_count = bl_oral_count + 3 if tercile == 3 
					replace bl_oral_count = bl_oral_count + 2 if tercile == 2
					replace bl_oral_count = bl_oral_count + 1 if tercile == 1 
		
			gen bl_obj_count1 = 0
				replace bl_obj_count1 = 1 if s7_e2 == 4

			gen bl_obj_count2 = 0
				replace bl_obj_count2 = 1 if s8_e2 == 12
	
			gen obj_count = bl_obj_count1 + bl_obj_count2
	
			gen bl_select_num = bt8 + bt9
	*/


/*******************************************************************************
	3. ANSIEDAD MATEMATICA
********************************************************************************/

* A: Intranquilo (1)
* B: Calmado (2)

	generate bl_anxiety=0
			foreach var of varlist ansiedad* { 
				gen `var'_d = (`var'==1) 
					replace `var'=0 if `var'==2 // No ansioso
					replace `var'=. if `var'==99 // No respondio
					replace bl_anxiety = bl_anxiety + 1 if `var'==1
			}
			*
			tab bl_anxiety // para reporte
						
						
/*******************************************************************************
	4. EGRA
********************************************************************************/					
			
			global s13 "s13_e1 s13_e2 s13_e3" //
					
				foreach var of varlist $s13 { 
					replace `var'=0 if `var'==99
					replace `var'=0 if `var'==2	
				}			
				*	
	gen n=1				
	
	*s13	
	** HAY QUE LIMPIAR LAS ETIQUETAS DE LAS VARIABLES :( 
	la var s13_e1 "Color del perro de Luis"
	la var s13_e2 "X1"
	la var s13_e3 "X2"

	*EGRA SCORE*
				gen bl_egra_score = s13_e1 + s13_e2 + s13_e3		
					
		
/*******************************************************************************
	5. ETNOMATEMÁTICA
********************************************************************************/
* Puntaje máximo: 8 puntos
	
		global s14 "s14_e1 s14_e2 s14_e3" // reconocer figuras - 3 ptos
		global s16 "s16_e1 s16_e2" // seleccion de numeros - 2 pto
		global s15 "s15_e2" //contar objetos 1
		global s17 "s17_e1 s17_e2" //sumar y restar - 2 ptos

				foreach var of varlist $s14 $s16 {
				*foreach var of varlist $s14 $s16 $s15 $s17 {   // en caso se cambié el "88"
						replace `var'=0 if `var'==99 // cambió de . a 0
						replace `var'=0 if `var'==. // cambió de . a 0
						*replace `var'=0 if `var'==88
				}
				*

**ETHNOMATH SCORE

		gen bl_ethnomath= 0 // puntaje maximo es de 16 (Ha cambiado el puntaje máximo)

				foreach var of varlist $s14 $s16 { 
						label var `var' ""
						replace bl_ethnomath = bl_ethnomath + 1 if `var'==1 
				}
					 
			*replace bl_ethnomath = bl_ethnomath + 1 if s15_e1 == 4 // contar objetos 1 (1 pto)
				replace bl_ethnomath = bl_ethnomath + 1 if s15_e2 == 4  
					
				replace bl_ethnomath = bl_ethnomath + 1 if s17_e1==3 // Sumar y restar 
				replace bl_ethnomath = bl_ethnomath + 1 if s17_e2==1


				
/*******************************************************************************
	6. IDENTIDAD CULTURAL
********************************************************************************/	

*CULTURA SCORE* // MAX score = 8 

		g bl_cultura=0  //  score según elección de objetos ngabe
						replace bl_cultura=bl_cultura + 1 if vestido==0  // preferencia
						replace bl_cultura=bl_cultura + 1 if mochila==0
						replace bl_cultura= bl_cultura + 1 if jeki==1

		global cul "kra nagua jeki" // este sí se puede sumar 

			foreach var of varlist $cul {  // conocimiento
					replace `var'=0 if `var'==99
					replace `var'=0 if `var'==.

			}
			*					
			foreach var of varlist $cul { 
					label var `var' ""
					replace bl_cultura = bl_cultura + 1 if `var'==1
			}
		* Preferencias y conocimientos x separado		
				
					
* cultural identity per area of analysis 

	gen bl_conocimiento =0
		replace bl_conocimiento=1 if kra==1
		replace bl_conocimiento=bl_conocimiento+1 if nagua==1
		replace bl_conocimiento=. if kra==. & nagua==.


	gen bl_percepciones =0
		replace bl_percepciones=1 if vestido==0
		replace bl_percepciones=bl_percepciones+1 if mochila==0
		replace bl_percepciones=. if vestido==. & mochila==.


	* actitudes =	jeki  *	
	
/*******************************************************************************
	8. COMPRENSIÓN ORAL NGABERE
********************************************************************************/
	*g n=1
			global s21 "s21_e1 s21_e2" //
					
				foreach var of varlist $s21 { 
						tab `var', m
						replace `var'=0 if `var'==99 // para que contabilice total de aciertos binarios 
						replace `var'=0 if `var'==2
				}	
				*
			la var s21_e1 "Sabe responder nombre en ngäbere"
			la var s21_e2 "Sabe responder edad en ngäbere"
		
					
		
** EGRA NGABE SCORE **		
		g bl_egra_ngb=0
				foreach var of varlist $s21 { 
						label var `var' ""
						replace bl_egra_ngb = bl_egra_ngb + 1 if `var'==1
				}
				*
				
				su bl_egra_ngb, de

				
/*******************************************************************************
	9. PERCEPCIONES
********************************************************************************/			

	rename s22_e1 bl_percepcion_mate
	rename s22_e2 bl_autoperc_mate
	rename s22_e3 bl_perc_gender
	rename s22_e4 bl_perc_etnia
	
	la var bl_percepcion_mate "BL Percepciones hacia las mate"
	la var bl_autoperc_mate "BL Autopercepciones hacia las mate"
	


/*******************************************************************************
/*******************************************************************************

			DOUBLE STANDARDIZATION - FOLLOWING LEUNG & BOND (1989)

********************************************************************************/
********************************************************************************/
	
	
* STEP 1. Estandarizar cada seccion (controlar el average, ajustar valores extremos en el raw data)

*EGMA_Z				
				/*Espacialidad y medidas */
				gen bt1 = 0 // Medidas
					replace bt1 = 1 if s1_e1 == 1   
					replace bt1 = bt1+1 if s1_e2 == 1  
					label var bt1 "Espacialidad I"     
					
				gen bt2 = 0 // Espacialidad
					replace bt2 = 1 if s2_e1 == 1   
					replace bt2 = bt2+1 if s2_e2 == 1
					label var bt2 "Espacialidad II"			
					
				/*discriminación de cantidades*/
				gen bt3a = 0
					replace bt3a = 1 if s3_e1 == 1   
					replace bt3a = bt3+1 if s3_e2 == 1			
					replace bt3a = bt3+1 if s3_e3 == 1
					label var bt3a "Discriminación de cantidades I"					
				
				gen bt3b = 0
					replace bt3b = 1 if s4_e1 == 1   
					label var bt3b "Discriminación de cantidades II"
					
				gen bt3 = bt3a+bt3b
					label var bt3 "Discriminación de cantidades"
					
				/*reconocer figuras*/		
				gen bt4 = 0
					replace bt4 = 1 if s5_e1 == 1   
					replace bt4 = bt4+1 if s5_e2 == 1
					replace bt4 = bt4+1 if s5_e3 == 1
					replace bt4 = bt4+1 if s5_e4 == 1
					label var bt4 "Reconocer figuras"	
				
				/*conteo oral*/ 
				gen bt5 = s6_e1 
					replace bt5 = 0 if bt5 == .
					sum bt5
					label var bt5 "Conteo oral"	
					
				/*contar objetos*/ 
				gen bt6 = s7_e2
					replace bt6 = 0 if bt6 == 99 					
					replace bt6 = 4 if bt6 > 4                //esto podría ser un error de paraguay ya que premia a quién contó más de 4
					label var bt6 "Contar objetos I"	
		
				gen bt7 = s8_e2
					replace bt7 = 0 if bt7 == 99 
					replace bt7 = 12 if bt7 > 12                //esto podría ser un error de paraguay ya que premia a quién contó más de 4
					label var bt7 "Contar objetos II"	
					
				/*selección de número*/
				gen bt8 = 0
					replace bt8 = 1 if s9_e1 == 1   
					replace bt8 = bt8+1 if s9_e2 == 1
					replace bt8 = bt8+1 if s9_e3 == 1
					replace bt8 = bt8+1 if s9_e4 == 1
					label var bt8 "Selección de número I"
					
				gen bt9 = 0
					replace bt9 = 1 if s10_e1 == 1   
					replace bt9 = bt9+1 if s10_e2 == 1
					replace bt9 = bt9+1 if s10_e3 == 1
					replace bt9 = bt9+1 if s10_e4 == 1
					label var bt9 "Selección de número II"					
					
				/*Nombrar números*/
				gen bt10 = s11_total
					replace bt10=0 if s11_total==.
					label var bt10 "Nombrar números"	
					
				/*suma y resta*/
				gen bt11 = 0
					replace bt11 = 1 if s12_e1 == 3   
					replace bt11 = bt11+1 if s12_e2 == 4
					replace bt11 = bt11+1 if s12_e3 == 1
					replace bt11 = bt11+1 if s12_e4 == 2
					replace bt11 = bt11+1 if s12_e5 == 3
					label var bt11 "Suma y resta"
					

* STEP 2. Estandarizar el score (controlar el SD, como todo va para una dirección, es más dificil observar valores extremos, x esta razón es preferble la doble estanda.)
/*STANDARIZATION PROCESS - following Gertler et al. (forthcoming)*/
				forvalues x = 1/11  {
						sum bt`x' if treatment == 0
						gen bt`x'_sd = (bt`x'-r(mean))/r(sd)
				}																					
				*
				gen bl_math_score_sd0 = (bt1_sd + bt2_sd + bt3_sd + bt4_sd + bt5_sd + bt6_sd + bt7_sd + bt8_sd + bt9_sd + bt10_sd + bt11_sd)/11
				sum bl_math_score_sd0 if treatment == 0					
				gen bl_egma_z = (bl_math_score_sd0 - r(mean))/r(sd)
					label var bl_egma_z "Puntaje - Línea de base"										
					


					
*EGRA_Z		
			gen bt13=0
				replace bt13 = 1 if s13_e1 == 1
				replace bt13 = bt13+1 if s13_e2 == 1
				replace bt13 = bt13+1 if s13_e3 == 1
				label var bt13 "Egra en español"
				
			sum bt13
			sum bt13 if treatment == 0	
			gen bl_egra_z = (bt13-r(mean))/r(sd)	
					
* ETNO_Z
			/*Reconocer figuras */
			gen bt14 = 0
				replace bt14 = 1 if s14_e1 == 1
				replace bt14 = bt14+1 if s14_e2 == 1
				replace bt14 = bt14+1 if s14_e3 == 1
				label var bt14 "reconocer figuras ngabes"
				
			/*Seleccion de numeros*/
			gen bt16=0
				*replace bt16 = 1 if s16_e1 == 1
				replace bt16 = 1 if s16_e2 == 1
				label var bt16 "seleccion de numeros"
				
				
			/*Contar objetos*/			
			gen bt15 = s15_e1
				replace bt15 = 4 if bt15 > 4                
				label var bt15 "Contar objetos I"
				
			/*sumar y restar*/				
			gen bt17 = 0
				replace bt17 = 1 if s17_e1 == 3     
				replace bt17 =bt17+ 1 if s17_e2 == 1                
				label var bt17 "sumas y restas"
						
				
				forvalues x = 14/17  {                    //Gertler et al. 
					sum bt`x' if treatment == 0
					gen bt`x'_sd = (bt`x'-r(mean))/r(sd)
				}	
						
			gen bl_etnomath_score_z = (bt14_sd + bt15_sd + bt16_sd + bt17_sd)/4
			sum bl_etnomath_score_z if treatment == 0					
			gen bl_etnomate_z = (bl_etnomath_score_z - r(mean))/r(sd)
			label var bl_etnomate_z "Baseline ethnomath score (sd)"



					
* ID CULTURAL_Z  // modificacion 08/09/2019

			gen kra1=0
				replace kra1=1 if kra==1
				
			gen nagua1=0
				replace nagua1=1 if nagua==1
				
			gen vestido1=0
				replace vestido1=1 if vestido==0
				
			gen mochila1=0
				replace mochila1=1 if mochila==0
				
			gen jeki1=0
				replace jeki1=1 if jeki==1
				
			
			global cul1 "kra1 nagua1 vestido1 mochila1 jeki1"			
				
				foreach var of varlist $cul1 { 
						sum `var' if treatment == 0
						gen `var'_sd = (`var'-r(mean))/r(sd)
				}	
				*

			gen bl_cultura_score_z = (kra1_sd+ nagua1_sd + vestido1_sd + mochila1_sd + jeki1_sd)/5
			sum bl_cultura_score_z if treatment == 0					
			gen bl_cultura_z = (bl_cultura_score_z - r(mean))/r(sd)
				label var bl_cultura_z "Baseline cultura score (sd)"
				
			*Desagregado
				
			gen bl_conocimientos_score_z = (kra1_sd + nagua1_sd)/2
			sum bl_conocimientos_score_z if treatment == 0					
			gen bl_conocimientos_z = (bl_conocimientos_score_z - r(mean))/r(sd)
				label var bl_conocimientos_z "Baseline conocimientos score (sd)"

			gen bl_percepciones_score_z = (vestido1_sd + mochila1_sd)/2
			sum bl_percepciones_score_z if treatment == 0					
			gen bl_percepciones_z = (bl_percepciones_score_z - r(mean))/r(sd)
				label var bl_percepciones_z "Baseline percepciones score (sd)"
				
			sum jeki1_sd if treatment==0
			gen bl_actitudes_z = (jeki1_sd - r(mean))/r(sd)
				label var bl_actitudes_z "Baseline actitudes score (sd)"
				
				

* EGRA_NGB_Z		
	
			gen bt21=0
				replace bt21=1 if s21_e1 == 1
				replace bt21=bt21+1 if s21_e2 == 1
				label var bt21 "Egra en ngabere"
				
			sum bt21 if treatment == 0					
			gen bl_egra_ngb_z = (bt21 - r(mean))/r(sd)		
				la var bl_egra_ngb_z "EGRA en ngabere"
				
* ANSIEDAD

			sum bl_anxiety if treatment == 0					
			gen bl_ansiedad_z = (bl_anxiety - r(mean))/r(sd)
			lab var bl_ansiedad_z "Baseline Ansiedad (sd)" 


			foreach var of varlist sex time_elapsed nr bl_math_score bl_anxiety bl_egra_score bl_egra_ngb bl_ethnomath bl_cultura bl_ngabe{
				replace `var'=. if consent==0 // para todas las variables, missing, pero para consent,no porque lo quiero contabilizar
			}				
			*

		
			
********************************************************************************

* Last vars related to treatment assignment		

// gen dummy var "Area comarcal vs Zona aledaña"
	gen zone=0
		replace zone=1 if r_area==3 | r_area==4 | r_area==6 // Area comarcal
		la def comarca 1 "Area comarcal" 0 "Zona aledaña"
		la val zone comarca
		la var zone "Área Comarcal"

// STRATA

	gen strata= string(r_area) + string(prek_tipo) // Poner stratas en la de limpieza de datos
		tab strata, gen(strata) // STRATA PTY
		destring strata, replace
				
// POOL TREATMENT
				
	gen pool = 0
		replace pool =1 if treatment==1 | treatment==2	
		la def pooled 0 "Control" 1 "Tratamiento" 
		la val pool pooled		
		la var pool "Tratamiento"

// PER TREATMENT
	gen t1=0
		replace t1=1 if treatment==1
		label var t1 "Programa Bilingüe"
	
	gen t2=0
		replace t2=1 if treatment==2
		label var t2 "Programa Intercultural"	
		
// Between treatments		
	gen treats = t1 // Comparison between treatments
	replace treats=. if treatment==0
	la var treats "Bilingüe vs Intercultural"	
		
//RECODE
	recode horario (7=1) (8=0)
	label define horario 0 "(Tarde) Vespertino" 1 "(Mañana) Matutino"				
	label val horario horario				

	
	* Saving file*
				save "$dta\Estudiantes_BL_prep.dta", replace

				codebookout "$dta\Codebook_Estudiantes_BL_prep.xls", replace

	
							** THE END **
