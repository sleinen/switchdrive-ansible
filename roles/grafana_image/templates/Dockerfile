FROM grafana/grafana:{{grafana_version}}

MAINTAINER Christian Schnidrig

RUN mkdir /plugins && \
    grafana-cli --pluginsDir "/plugins" plugins install grafana-piechart-panel && \
    grafana-cli --pluginsDir "/plugins" plugins install grafana-simple-json-datasource && \
    grafana-cli --pluginsDir "/plugins" plugins install percona-percona-app 

RUN sed -i 's/expr=\(.\)\.replace(\(.\)\.expr,\(.\)\.scopedVars\(.*\)var \(.\)=\(.\)\.interval/expr=\1.replace(\2.expr,\3.scopedVars\4var \5=\1.replace(\6.interval, \3.scopedVars)/' /usr/share/grafana/public/app/plugins/datasource/prometheus/datasource.js && \
    sed -i 's/,range_input/.replace(\/"{\/g,"\\"").replace(\/}"\/g,"\\""),range_input/; s/step_input:""/step_input:this.target.step/' /usr/share/grafana/public/app/plugins/datasource/prometheus/query_ctrl.js



