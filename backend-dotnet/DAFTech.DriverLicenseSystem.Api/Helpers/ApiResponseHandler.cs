namespace DAFTech.DriverLicenseSystem.Api.Helpers;

using Microsoft.AspNetCore.Mvc;

public class ApiResponseHandler
{
    public static ActionResult Success<T>(T data, string message = "Success")
    {
        return new OkObjectResult(new ApiResponse<T>
        {
            Success = true,
            Message = message,
            Data = data
        });
    }

    public static ActionResult Error<T>(string message, T? data = default)
    {
        return new ObjectResult(new ApiResponse<T>
        {
            Success = false,
            Message = message,
            Data = data
        })
        {
            StatusCode = 500
        };
    }

    public static ActionResult Error(string message)
    {
        return new ObjectResult(new ApiResponse<object>
        {
            Success = false,
            Message = message,
            Data = null
        })
        {
            StatusCode = 500
        };
    }

    public static ActionResult NotFound(string message)
    {
        return new NotFoundObjectResult(new ApiResponse<object>
        {
            Success = false,
            Message = message,
            Data = null
        });
    }

    public static ActionResult Unauthorized(string message)
    {
        return new UnauthorizedObjectResult(new ApiResponse<object>
        {
            Success = false,
            Message = message,
            Data = null
        });
    }

    public static ActionResult Conflict(string message)
    {
        return new ConflictObjectResult(new ApiResponse<object>
        {
            Success = false,
            Message = message,
            Data = null
        });
    }

    public static ActionResult BadRequest(string message)
    {
        return new BadRequestObjectResult(new ApiResponse<object>
        {
            Success = false,
            Message = message,
            Data = null
        });
    }
}

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public T? Data { get; set; }
}
