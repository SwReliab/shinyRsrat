# shinyRsrat

A web-based application for software reliability assessment.

## Installation

### Required R packages

They are installed with `remotes` or `devtools` packages.

- Rsrat: https://github.com/SwReliab/Rsrat
- Rphsrm: https://github.com/SwReliab/Rphsrm
- gof4srm: https://github.com/SwReliab/gof4srm

```
install.packages("remotes")
remotes::install_github("SwReliab/gof4srm")
remotes::install_github("SwReliab/Rphsrm")
# Rsrat is automatically installed when Rphsrm or gof4srm is installed.
```

### Try it with shinyapps

You can try the application just by visiting to

- URL: [https://okamumu.shinyapps.io/Rsrat/](https://okamumu.shinyapps.io/Rsrat/)

Note: The above is just a trial for this application.

### Use Docker

The application runs on your local server with Docker. Please run

```
docker-compose up -d
```

If you check the log of application, run

```
docker-compose up
```

## Usage

### Bug/Fault Data

There are two types of bug data: fault count data and time data. The fault count data is a time series of the number of discovered bugs for a time period. The example of the fault count data is as follows.

|Days|Faults|
|-:|-:|
|31|5|
|28|7|
|31|3|
|30|1|
|31|0|
|30|1|

The first column indicates the number of days and the second column is the number of discovered bugs for the time duration. 

The time data consists of a sequence of time intervals for each bug. The typical format is

|ID|Time interval|
|-:|-:|
|1|30|
|2|3|
|3|10|
|4|1|
|-|12|

In the above table, the 1st bug is discovered at 30 unit time (such as CPU execution time). The 2nd bug is found after 3 unit time after finding the 1st bug. The last row indicates that any bug has not been detected in 12 unit time after finding the last (4th) bug. In the application, the above time data is rewritten by the following table called the generalized data.

|Time|Faults|Indicator|
|-:|-:|-:|
|30|0|1|
|3|0|1|
|10|0|1|
|1|0|1|
|12|0|0|

The first column indicates the time intervals for the bug detection times. The second column indicates the number of detected bugs during the time interval. The third column means the indicator that the bug is detected just at the end time of the time interval. The above format involves both fault count data and time data.

The application uses the standard fault count data format and the generalized data format. By pushing `Browse` button, we can upload the CSV file for two formats from a local file. After uploading, we choose the columns that are used for time intervals, the number of faults and the indicator meaning a bug is detected at the end of interval or not.

### Estimation

After uploading and choosing the columns, we select the SRGMs estimated from the list of models in `Use`. Also, we can put the number of phases of phase-type SRGM into the textbox of `Phase`. This textbox allows to put a list representation like `10,20,30` and a command of R `seq(10,30,10)`. In this case, the application uses the phase-type SRGMs with 10, 20 and 30 phases for the estimation. Note that the estimation time becomes larger than we choose the phase-type SRGM with the large number of phases. In our experience, the model with 200 phases is the limitation.

The estimation starts by pushing `Estimate` button. After finishing the estimation, the application draws the estimated mean value functions and their differences on observed time points. Also, the results of goodness-of-fit; the maximum log-likelihood (llf), AIC and the p-value of KS test (ks) are listed in the table. In the table, `df` indicates the number of model parameters. If we use EIC (extended information criterion), check `Use EIC` and push `Estiamte` button. The models to be listed are selected by the checkbox in `Models`.

### Evaluation

After finishing the estimation, the reliability criteria are listed in the tab `Evaluation`. The criteria are

- Total: The expected number of total bugs
- Residual: The expected number of residual bugs
- FFP: The probability that the software does not include any bug.
- iMTBF: An alternative MTBF (mean time between failures). It is regarded as the expected time to detect the next bug.
- cMTBF:  An alternative MTBF (mean time between failures). It is regarded as the expected time to detect the next bug.


