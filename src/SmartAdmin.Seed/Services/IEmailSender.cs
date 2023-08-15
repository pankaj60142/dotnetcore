#region Using

using System.Threading.Tasks;

#endregion

namespace SmartAdmin.Seed.Services
{
    public interface IEmailSender
    {
        Task<bool> SendEmailAsync(string email, string subject, string message);
        Task SendDiagramEmailAsync(string email, string subject, string message,string fileName);


        Task<string> ShareFolderEmailAsync(string email, string subject, string message);

    }
}
