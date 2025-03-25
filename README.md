# FIND 
#### Fishing Indicators

## What is this?
This is a basic near $0 cost app hosted in AWS.  The app queries various APIs to gather at-a-glance fishing weather conditions.  The application uses Python and TypeScript and is deployed via Terraform using GitLab.

## Why is this here?
I love fishing, I love data, I love technology.  I wanted to create a project that I could use, while also providing an example of how several pieces of technology can be plumbed together.  In learning online I have often found that many guides show how one singular component works by itself, but not how it could work within a larger system.  I hope this might help someone in the future.


## Architecture
- S3 + Cloudfront + ACM to host a static Angular Frontend
- API Gateway + Lambda to host the backend
- Multiple AWS Accounts for environment segregation

## How to use
To test and run locally:

    docker-compose up --build
    
This will launch 2 containers (frontend and backend)
The backend is a simple "API Gateway" in Flask which forwards the requests to the Lambda function in a similar way that API Gateway does in AWS.

## Notes
- This app is not a secure app.  It is designed to be publically accessible. Thusly there is no authentication.  
- I am not a frontend developer.  It is pretty ugly.

## Status
This project is currently in development.  In it's current incarnation here it is close to MVP status.  There are a few items that need ironing out, but it deploys and runs, and that's what counts.

## License
GPL v3
FWIW There is nothing special here, but because I learned everything I know from others who were generous enough to share their knowledge, I hope this can help someone else figure out how to do "that ont weird thing in Terraform".  