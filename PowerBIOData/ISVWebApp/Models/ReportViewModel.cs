﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Microsoft.PowerBI.Api;
using Microsoft.PowerBI.Api.V1.Models;

namespace ISVWebApp.Models
{
    public class ReportViewModel
    {
        public Report Report { get; set; }

        public string AccessToken { get; set; }
    }
}