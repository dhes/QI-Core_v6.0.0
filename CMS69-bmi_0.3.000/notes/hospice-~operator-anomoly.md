# Problem
Given
```
code "Hospice care [Minimum Data Set]": '45755-6' from "LOINC" display 'Hospice care [Minimum Data Set]'
code "Yes (qualifier value)": '373066001' from "SNOMEDCT" display 'Yes (qualifier value)'
...
exists (([ObservationScreeningAssessment: "Hospice care [Minimum Data Set]"]).isAssessmentPerformed()) HospiceAssessment
        where HospiceAssessment.value ~ "Yes (qualifier value)"
          and HospiceAssessment.effective.toInterval() overlaps day of "Measurement Period"

...
```
with an Observation.value
```
        "valueCodeableConcept": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "373066001",
              "display": "Yes (qualifier value)",
              "userSelected": true
            }
          ]
        }

```
produces OperationOutcome error
```
{
          "severity": "error",
          "code": "exception",
          "diagnostics": "Exception for subjectId: Patient/736b5472-4a6f-4278-80d3-373d1c78c4c5, Message: Could not resolve call to operator 'ToQuantity(org.hl7.fhir.r4.model.CodeableConcept)' in library 'FHIRHelpers'."
        }
```
with this server log output. 
```
Exception for subjectId: Patient/736b5472-4a6f-4278-80d3-373d1c78c4c5, Message: Could not resolve call to operator 'ToQuantity(org.hl7.fhir.r4.model.CodeableConcept)' in library 'FHIRHelpers'.

org.opencds.cqf.cql.engine.exception.CqlException: Could not resolve call to operator 'ToQuantity(org.hl7.fhir.r4.model.CodeableConcept)' in library 'FHIRHelpers'.
	at org.opencds.cqf.cql.engine.elm.executing.FunctionRefEvaluator.pickFunctionDef(FunctionRefEvaluator.java:139)
	at org.opencds.cqf.cql.engine.elm.executing.FunctionRefEvaluator.resolveFunctionRef(FunctionRefEvaluator.java:82)
	at org.opencds.cqf.cql.engine.elm.executing.FunctionRefEvaluator.resolveOrCacheFunctionDef(FunctionRefEvaluator.java:67)
	at org.opencds.cqf.cql.engine.elm.executing.FunctionRefEvaluator.internalEvaluate(FunctionRefEvaluator.java:30)
	at org.opencds.cqf.cql.engine.execution.EvaluationVisitor.visitFunctionRef(EvaluationVisitor.java:28)
	at org.opencds.cqf.cql.engine.execution.EvaluationVisitor.visitFunctionRef(EvaluationVisitor.java:14)
	at org.cqframework.cql.elm.visiting.BaseElmClinicalVisitor.visitExpression(BaseElmClinicalVisitor.java:38)
	at org.opencds.cqf.cql.engine.execution.EvaluationVisitor.visitGreater(EvaluationVisitor.java:196)
	at org.opencds.cqf.cql.engine.execution.EvaluationVisitor.visitGreater(EvaluationVisitor.java:14)
	at org.cqframework.cql.elm.visiting.BaseElmVisitor.visitBinaryExpression(BaseElmVisitor.java:399)
	at org.cqframework.cql.elm.visiting.BaseElmClinicalVisitor.visitBinaryExpression(BaseElmClinicalVisitor.java:97)
	at org.cqframework.cql.elm.visiting.BaseElmVisitor.visitOperatorExpression(BaseElmVisitor.java:293)
	at org.cqframework.cql.elm.visiting.BaseElmClinicalVisitor.visitOperatorExpression(BaseElmClinicalVisitor.java:66)
	at org.cqframework.cql.elm.visiting.BaseElmVisitor.visitExpression(BaseElmVisitor.java:257)
	at org.cqframework.cql.elm.visiting.BaseElmClinicalVisitor.visitExpression(BaseElmClinicalVisitor.java:49)
	at org.opencds.cqf.cql.engine.execution.EvaluationVisitor.visitAnd(EvaluationVisitor.java:68)
	at org.opencds.cqf.cql.engine.execution.EvaluationVisitor.visitAnd(EvaluationVisitor.java:14)
	at org.cqframework.cql.elm.visiting.BaseElmVisitor.visitBinaryExpression(BaseElmVisitor.java:385)
	at org.cqframework.cql.elm.visiting.BaseElmClinicalVisitor.visitBinaryExpression(BaseElmClinicalVisitor.java:97)
	at org.cqframework.cql.elm.visiting.BaseElmVisitor.visitOperatorExpression(BaseElmVisitor.java:293)
	at org.cqframework.cql.elm.visiting.BaseElmClinicalVisitor.visitOperatorExpression(BaseElmClinicalVisitor.java:66)
	at org.cqframework.cql.elm.visiting.BaseElmVisitor.visitExpression(BaseElmVisitor.java:257)
	at org.cqframework.cql.elm.visiting.BaseElmClinicalVisitor.visitExpression(BaseElmClinicalVisitor.java:49)
	at org.opencds.cqf.cql.engine.execution.EvaluationVisitor.visitAnd(EvaluationVisitor.java:68)
	at org.opencds.cqf.cql.engine.execution.EvaluationVisitor.visitAnd(EvaluationVisitor.java:14)
	at org.cqframework.cql.elm.visiting.BaseElmVisitor.visitBinaryExpression(BaseElmVisitor.java:385)
	at org.cqframework.cql.elm.visiting.BaseElmClinicalVisitor.visitBinaryExpression(BaseElmClinicalVisitor.java:97)
	at org.cqframework.cql.elm.visiting.BaseElmVisitor.visitOperatorExpression(BaseElmVisitor.java:293)
	at org.cqframework.cql.elm.visiting.BaseElmClinicalVisitor.visitOperatorExpression(BaseElmClinicalVisitor.java:66)
	at org.cqframework.cql.elm.visiting.BaseElmVisitor.visitExpression(BaseElmVisitor.java:257)
	at org.cqframework.cql.elm.visiting.BaseElmClinicalVisitor.visitExpression(BaseElmClinicalVisitor.java:49)
	at org.opencds.cqf.cql.engine.elm.executing.QueryEvaluator.evaluateWhere(QueryEvaluator.java:74)
	at org.opencds.cqf.cql.engine.elm.executing.QueryEvaluator.internalEvaluate(QueryEvaluator.java:194)
	at org.opencds.cqf.cql.engine.execution.EvaluationVisitor.visitQuery(EvaluationVisitor.java:1364)
	at org.opencds.cqf.cql.engine.execution.EvaluationVisitor.visitQuery(EvaluationVisitor.java:14)
	at org.cqframework.cql.elm.visiting.BaseElmVisitor.visitExpression(BaseElmVisitor.java:249)
	at org.cqframework.cql.elm.visiting.BaseElmClinicalVisitor.visitExpression(BaseElmClinicalVisitor.java:49)
	at org.opencds.cqf.cql.engine.elm.executing.ExpressionDefEvaluator.internalEvaluate(ExpressionDefEvaluator.java:26)
	at org.opencds.cqf.cql.engine.execution.EvaluationVisitor.visitExpressionDef(EvaluationVisitor.java:18)
	at org.opencds.cqf.cql.engine.execution.CqlEngine.evaluateExpressions(CqlEngine.java:240)
	at org.opencds.cqf.cql.engine.execution.CqlEngine.evaluate(CqlEngine.java:208)
	at org.opencds.cqf.fhir.cql.LibraryEngine.getEvaluationResult(LibraryEngine.java:352)
	at org.opencds.cqf.fhir.cr.measure.common.MeasureEvaluator.evaluate(MeasureEvaluator.java:309)
	at org.opencds.cqf.fhir.cr.measure.common.MeasureEvaluator.evaluate(MeasureEvaluator.java:104)
	at org.opencds.cqf.fhir.cr.measure.common.BaseMeasureEvaluation.evaluate(BaseMeasureEvaluation.java:83)
	at org.opencds.cqf.fhir.cr.measure.r4.R4MeasureProcessor.evaluateMeasure(R4MeasureProcessor.java:168)
	at org.opencds.cqf.fhir.cr.measure.r4.R4MeasureProcessor.evaluateMeasure(R4MeasureProcessor.java:92)
	at org.opencds.cqf.fhir.cr.measure.r4.R4MeasureProcessor.evaluateMeasure(R4MeasureProcessor.java:78)
	at org.opencds.cqf.fhir.cr.measure.r4.R4MeasureService.evaluate(R4MeasureService.java:74)
	at org.opencds.cqf.fhir.cr.hapi.r4.measure.MeasureOperationsProvider.evaluateMeasure(MeasureOperationsProvider.java:72)
	at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(DirectMethodHandleAccessor.java:103)
	at java.base/java.lang.reflect.Method.invoke(Method.java:580)
	at ca.uhn.fhir.rest.server.method.BaseMethodBinding.invokeServerMethod(BaseMethodBinding.java:264)
	at ca.uhn.fhir.rest.server.method.OperationMethodBinding.invokeServer(OperationMethodBinding.java:399)
	at ca.uhn.fhir.rest.server.method.BaseResourceReturningMethodBinding.doInvokeServer(BaseResourceReturningMethodBinding.java:146)
	at ca.uhn.fhir.rest.server.method.BaseResourceReturningMethodBinding.invokeServer(BaseResourceReturningMethodBinding.java:275)
	at ca.uhn.fhir.rest.server.method.OperationMethodBinding.invokeServer(OperationMethodBinding.java:356)
	at ca.uhn.fhir.rest.server.RestfulServer.handleRequest(RestfulServer.java:1201)
	at ca.uhn.fhir.rest.server.RestfulServer.doGet(RestfulServer.java:424)
	at ca.uhn.fhir.rest.server.RestfulServer.service(RestfulServer.java:1955)
	at jakarta.servlet.http.HttpServlet.service(HttpServlet.java:614)
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:195)
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:140)
	at org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:51)
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:164)
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:140)
	at org.springframework.web.filter.ServerHttpObservationFilter.doFilterInternal(ServerHttpObservationFilter.java:113)
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116)
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:164)
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:140)
	at org.springframework.web.filter.CharacterEncodingFilter.doFilterInternal(CharacterEncodingFilter.java:201)
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116)
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:164)
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:140)
	at org.apache.catalina.core.StandardWrapperValve.invoke(StandardWrapperValve.java:167)
	at org.apache.catalina.core.StandardContextValve.invoke(StandardContextValve.java:90)
	at org.apache.catalina.authenticator.AuthenticatorBase.invoke(AuthenticatorBase.java:483)
	at org.apache.catalina.core.StandardHostValve.invoke(StandardHostValve.java:115)
	at org.apache.catalina.valves.ErrorReportValve.invoke(ErrorReportValve.java:93)
	at org.apache.catalina.core.StandardEngineValve.invoke(StandardEngineValve.java:74)
	at org.apache.catalina.connector.CoyoteAdapter.service(CoyoteAdapter.java:344)
	at org.apache.coyote.http11.Http11Processor.service(Http11Processor.java:384)
	at org.apache.coyote.AbstractProcessorLight.process(AbstractProcessorLight.java:63)
	at org.apache.coyote.AbstractProtocol$ConnectionHandler.process(AbstractProtocol.java:905)
	at org.apache.tomcat.util.net.NioEndpoint$SocketProcessor.doRun(NioEndpoint.java:1741)
	at org.apache.tomcat.util.net.SocketProcessorBase.run(SocketProcessorBase.java:52)
	at org.apache.tomcat.util.threads.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1190)
	at org.apache.tomcat.util.threads.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:659)
	at org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:63)
	at java.base/java.lang.Thread.run(Thread.java:1583)
```
indicating a possible type match error. 

# Possible workarounds
## Try =, not ~

```
HospiceAssessment.value = "Yes (qualifier value)"
```
### Result
No effect 
## Unpack the CodeableConcept before matching
```
exists (HospiceAssessment.value.coding C
  where C.code = '373066001' and C.system = 'http://snomed.info/sct'
)
```
### Result
That seems implausible because, as ChatGPT puts it
```
Thanks for that clue — the error message “Invalid interval property name coding” suggests that the CQL compiler thinks HospiceAssessment.value is a primitive or a different type than expected (like an Interval or Quantity), not a CodeableConcept as you’d hoped.

This likely means that value is polymorphic, as in FHIR’s value[x], and the engine is unsure of the actual type at compile time. To fix this, you need to explicitly cast value to CodeableConcept before accessing .coding.
```
## Normalize the Coding with FHIRHelpers.ToConcept()
```
FHIRHelpers.ToConcept(HospiceAssessment.value) ~ "Yes (qualifier value)"
```
### Interesting error message. 
```
Could not resolve call to operator ToConcept with signature (choice<System.Quantity,System.Concept,System.String,System.Boolean,System.Integer,interval<System.Quantity>,System.Ratio,System.Time,System.DateTime,interval<System.DateTime>>).
```
## Use a ValueSet
```
HospiceAssessment.value in "Yes Snomed ValueSet"
```
## test without display
Strip the display field from your code declaration (or ensure it matches exactly what’s in the CodeableConcept.coding.display)

Here's the Execute CQL output before the change
```
BMI During Measurement Period=[]
Denominator=true
Denominator Exceptions=false
Denominator Exclusions=true
Documented High BMI During Measurement Period=[]
Documented Low BMI During Measurement Period=[]
Has Normal BMI=false
High BMI And Follow Up Provided=[]
High BMI Interventions Ordered=[]
High BMI Interventions Performed=[Procedure(id=c7b0a546-6d1b-40c9-b907-215d53fb5a37)]
Initial Population=true
Is Pregnant During Day Of Measurement Period=false
Low BMI And Follow Up Provided=[]
Low BMI Interventions Ordered=[]
Low BMI Interventions Performed=[]
Medical Reason For Not Documenting A Follow Up Plan For Low Or High BMI=[]
Medical Reason Or Patient Reason For Not Performing BMI Exam=[]
Numerator=false
Patient=Patient(id=736b5472-4a6f-4278-80d3-373d1c78c4c5)
Qualifying Encounter During Day Of Measurement Period=[Encounter(id=5b42b17c-c6e8-4321-9e4b-c5b027b50486)]
SDE Ethnicity=Tuple {
	"codes": [Code { code: 2135-2, system: urn:oid:2.16.840.1.113883.6.238, version: null, display: Hispanic or Latino }]
	"display": Hispanic or Latino
}
SDE Payer=[]
SDE Race=Tuple {
	"codes": [Code { code: 2028-9, system: urn:oid:2.16.840.1.113883.6.238, version: null, display: Asian }]
	"display": Asian
}
SDE Sex=null
```
and after there is no change. 
### Result
No effect. Same OperationOutcome error. ;(

## Print the resolved runtime type and value
In debug mode or via logging, confirm what is actually passed as the function argument — e.g., is it null, a list, or a malformed object? Sometimes value[x] may contain something odd (e.g., a list of CodeableConcepts instead of a single instance), which breaks resolution.

## Explicitly cast the value to CodeableConcept
```
(Cast as CodeableConcept) HospiceAssessment.value ~ "Yes (qualifier value)"
```

## Update cql-to-elm
Good idea anyway but had no effect. 

## Remove .isAssessmentPerformed

### Result
Same error message. 

## Change ObservationScreeningAssessment to SimpleObservation
Like this
```
exists ((([SimpleObservation: "Hospice care [Minimum Data Set]"])) HospiceAssessment
        where HospiceAssessment.value ~ "Yes (qualifier value)"
          and HospiceAssessment.effective.toInterval() overlaps day of "Measurement Period"
    )
```
has no effect. 
### Result
Same error. 

## Change  HospiceAssessment.value ~ "Yes (qualifier value)" to Equivalent(HospiceAssessment.value, "Yes (qualifier value)")

### Result
No change. 


