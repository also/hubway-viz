#rm -rf build
SITE=build/site
mkdir -p ${SITE}
cp scratch/*.* ${SITE}
coffee -c ${SITE}/*.coffee
sass ${SITE}/graph_everything.scss ${SITE}/graph_everything.css

mkdir -p ${SITE}/d3/lib/colorbrewer
cp scratch/d3/d3.v2.js ${SITE}/d3
cp scratch/d3/lib/colorbrewer/colorbrewer.js ${SITE}/d3/lib/colorbrewer/

mkdir ${SITE}/crossfilter
cp scratch/crossfilter/crossfilter.js ${SITE}/crossfilter

mkdir -p ${SITE}/jquery/dist
cp scratch/jquery/dist/jquery.js ${SITE}/jquery/dist
