using Azure.Identity;
using Azure.Storage;
using Azure.Storage.Queues;
using System;
using System.Security.Cryptography.X509Certificates;

/*
 * Install-Package Azure.Identity -IncludePrerelease
 * Install-Package Azure.Storage.Queues -Version 12.0.0-preview.3
 * */

namespace Receiver
{
    class Program
    {
        const string _queueUri = "https://sugarsusdata.queue.core.windows.net:443/observations";
        const string _tenantId = "microsoft.com"; // 72f988bf-86f1-41af-91ab-2d7cd011db47
        const string _clientId = "51db77bc-bd63-44ae-9b8c-267af4bb0b62";

        static void Main(string[] args)
        {
            Console.WriteLine("Message reader");
            var count = 0;
            var cert = GetCert("sugarsus-receiver");
            var cred = new ClientCertificateCredential(_tenantId, _clientId, cert);
            var queue = new QueueClient(new Uri(_queueUri), cred);
            while (true)
            {
                try
                {
                    var resp = queue.DequeueMessages();
                    foreach (var msg in resp.Value)
                    {
                        if (msg.DequeueCount > 3)
                        {
                            Console.WriteLine("Bad msg. Moving to dead letter queue");
                            // move the message to somewhere else where you can investigate it
                        }
                        else
                        {
                            Console.WriteLine($"Processing: {msg.MessageText}");
                        }
                        ++count;
                        queue.DeleteMessage(msg.MessageId, msg.PopReceipt);
                    }
                }
                catch (StorageRequestFailedException ex)
                {
                    Console.WriteLine("");
                    break;
                }
            }
            Console.WriteLine($"Processed {count} message(s).");
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
