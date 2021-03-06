//Load info from package.json
const pjson = require('./package.json');

const polka = require('polka');
const app = polka();

var cookieParser = require('cookie-parser');

const dotenv = require('dotenv');
dotenv.config();

const winston = require('winston');
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    //
    // - Write all logs with importance level of `error` or less to `error.log`
    // - Write all logs with importance level of `info` or less to `info.log`
    //
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'info.log' }),
  ],
});
//Log examples:
//logger.info('Some info');
//logger.error('Some error');

//Docs using Swagger
const doc = {
  info: {
      version: pjson.version,
      title: "Deployed.cc Server API",
      description: "Documentation for API for deployed.cc"
  },
  host: "deployed.cc",
  basePath: "/",
  schemes: ['http', 'https'],
  consumes: ['application/json'],
  produces: ['application/json'],
  tags: [
      {
          "name": "Service",
          "description": "Service Endpoints"
      }
  ]
}
const swaggerAutogen = require('swagger-autogen')()
const outputFile = './swagger_output.json'
const endpointsFiles = ['./routes/service']
swaggerAutogen(outputFile, endpointsFiles, doc)

const Parse = require('parse/node');
const ParseAppId = process.env.PARSE_APP_ID;
Parse.initialize(ParseAppId);

Parse.ParseAppId = ParseAppId;
Parse.serverURL = process.env.PARSE_SERVER_URL;
Parse.PARSE_MASTER_KEY = process.env.PARSE_MASTER_KEY;

const { json } = require('body-parser');
const cors = require('cors');
var allowedOrigins = ['http://localhost:3000',
  'http://localhost:4002',
  'https://deployed.cc'];

app.use(cors({
  credentials: true, origin: function (origin, callback) {
    // allow requests with no origin 
    // (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) === -1) {
      var msg = 'The CORS policy for this site does not ' +
        'allow access from the specified Origin.';
      return callback(new Error(msg), false);
    }
    return callback(null, true);
  }
}));
app.use(json());
app.use(cookieParser());

//Create routes
require("./routes/server")(app, logger, Parse);
require("./routes/job")(app, logger, Parse);
require("./routes/config")(app);
require("./routes/domain")(app);
require("./routes/environment")(app, logger, Parse);
require("./routes/event")(app);
require("./routes/health")(app);
require("./routes/service")(app, logger, Parse);
require("./routes/project")(app, logger, Parse);
require("./routes/deploy")(app, logger);
require("./routes/user")(app);

//Start the job manager
require("./internal/job_manager")(logger, Parse);

//Start client monitoring queue
//const monitoring = require("./internal/client_monitoring");
//setInterval(monitoring.getServerStats, process.env.CHECK_CLIENT_HEALTH_INTERVAL);

app.listen(process.env.PORT, err => {
  if (err) throw err;
  console.log(`> Deployed Server is running on port ${process.env.PORT}`);
});
