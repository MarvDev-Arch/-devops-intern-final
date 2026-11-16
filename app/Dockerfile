FROM nginx:1.27.5-alpine3.21-slim

ARG BUILD_SHA=local-build

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup && \
    mkdir -p /tmp/client_temp /tmp/proxy_temp \
             /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    chown -R appuser:appgroup /usr/share/nginx/html \
                              /var/cache/nginx \
                              /var/log/nginx \
                              /tmp

COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html/index.html

RUN sed -i "s/__BUILD_SHA__/${BUILD_SHA}/g" \
    /usr/share/nginx/html/index.html

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/healthz"]

CMD ["nginx", "-g", "daemon off;"]