FROM node:20.18.1 AS builder

RUN npm install -g typescript @angular/cli

WORKDIR /app
COPY . /app
RUN npm install

ARG BRANCH=dev
ARG ENVIRONMENT=development
RUN if [ "$BRANCH" = "main" ]; then \
        ENVIRONMENT=production; \
        ng build --configuration ${ENVIRONMENT} --output-path=/app/dist/${ENVIRONMENT}; \
    else \
        ENVIRONMENT=development; \
        ng build --configuration ${ENVIRONMENT} --output-path=/app/dist/${ENVIRONMENT}; \
    fi

FROM scratch
# ARG BRANCH=dev
ARG ENVIRONMENT=development
# RUN if [ "$BRANCH" = "main" ]; then \
#         ENVIRONMENT=production; \
#     else \
#         ENVIRONMENT=development; \
#     fi
COPY --from=builder /app/dist/${ENVIRONMENT}/browser output_for_s3

