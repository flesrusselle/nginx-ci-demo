# Simple nginx static site Dockerfile

FROM nginx:1.24-alpine

# Remove the default site (optional) and copy our static files
COPY app/index.html /usr/share/nginx/html/index.html
COPY app/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
