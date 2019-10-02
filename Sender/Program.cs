using Azure.Identity;
using Azure.Storage.Queues;
using System;
using System.Security.Cryptography.X509Certificates;

/*
 * 
 * Install-Package Azure.Storage.Queues -Version 12.0.0-preview.3
 * */

namespace Sender
{
    class Program
    {
        const string _queueUri = "https://sugarsusdata.queue.core.windows.net:443/observations";
        const string _tenantId = "microsoft.com"; // 72f988bf-86f1-41af-91ab-2d7cd011db47
        const string _clientId = "ab080cc1-fc62-42ed-ad21-e32b23292fef";

        static void Main(string[] args)
        {
            Console.WriteLine("Message sender");
            var cert = GetCert("sugarsus-sender1");
            var cred = new ClientCertificateCredential(_tenantId, _clientId, cert);
            var queue = new QueueClient(new Uri(_queueUri), cred);
            var count = 0;
            Console.WriteLine("Press any key to send message or 'x' to stop.");
            var key = Console.ReadKey();
            while (key.KeyChar != 'x')
            {
                var resp = queue.EnqueueMessage($"{count}. Test {DateTime.Now}");
                ++count;
                key = Console.ReadKey();
            }
            Console.WriteLine();
            Console.WriteLine($"Sent {count} message(s).");
            Console.ReadLine();
        }

        private static X509Certificate2 GetCert(string subjectName)
        {
            using (var store = new X509Store(StoreLocation.CurrentUser))
            {
                store.Open(OpenFlags.ReadOnly);
                X509Certificate2Collection cers = store.Certificates.Find(X509FindType.FindBySubjectName, subjectName, false);
                if (cers.Count > 0)
                {
                    return cers[0];
                };
            }
            return null;
        }
    }
}
